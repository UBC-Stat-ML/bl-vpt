package iscm

import bayonet.distributions.Random
import blang.System
import blang.engines.internals.EngineStaticUtils
import blang.engines.internals.Spline
import blang.engines.internals.Spline.MonotoneCubicSpline
import blang.engines.internals.SplineDerivatives
import blang.engines.internals.factories.PT
import blang.engines.internals.factories.PT.Column
import blang.engines.internals.factories.PT.MonitoringOutput
import blang.engines.internals.factories.SCM
import blang.engines.internals.schedules.FixedTemperatureSchedule
import blang.engines.internals.schedules.TemperatureSchedule
import blang.engines.internals.schedules.UserSpecified
import blang.inits.Arg
import blang.inits.DefaultValue
import blang.inits.experiments.tabwriters.TabularWriter
import blang.inits.experiments.tabwriters.TidySerializer
import blang.runtime.Runner
import blang.runtime.SampledModel
import com.google.common.primitives.Doubles
import java.util.List
import java.util.concurrent.TimeUnit

class ISCM extends SCM { 
   
  @Arg  @DefaultValue("5")
  public int nRounds = 5;
  
  @Arg  @DefaultValue("true")
  public boolean useExtrapolationForLeftPoint = true;
  
  @Arg                       @DefaultValue("20")
  public int initialNumberOfSMCIterations = 20;
  
  SampledModel model;
  
  var currentRound = 0
  override performInference() {
    var numberOfSMCIterations = initialNumberOfSMCIterations;
    estimateISCMStatistics = true;
    
    var TemperatureSchedule schedule = new FixedTemperatureSchedule() => [ nTemperatures = initialNumberOfSMCIterations ]
    for (currentRound = 0; currentRound < nRounds; currentRound++) {
      System.out.indentWithTiming("Round(" + (currentRound+1) + "/" + nRounds + ")") 
      writer(ISCMOutput::budget).printAndWrite(
        "nParticles" -> nParticles, 
        "nIterations" -> numberOfSMCIterations
      )
      prevResamplingIter = 0
      prevResamplingAnnealingParam = 0.0
      temperatureSchedule = schedule
      val streams = Random.parallelRandomStreams(random, nParticles)
      val approx = getApproximation(initialize(model, streams), 1.0, model, streams, false)
      
      // increase number of particles, temperatures
      if (nResamplingRounds == 0) {
        System.out.println(" --> no resampling performed: increasing # particles x2")
        nParticles *= 2
      } else {
        System.out.println(" --> increasing # particles x1.4; # iteration x1.4")
        numberOfSMCIterations = Math::ceil(numberOfSMCIterations * Math::sqrt(2.0)) as int
        nParticles            = Math::ceil(nParticles            * Math::sqrt(2.0)) as int
      }
      
      // update schedule
      schedule = updateSchedule(annealingParameters, incrementalLogWeightSDs, numberOfSMCIterations, currentRound)  
      
      random = streams.get(0)
      
      reportRoundStatistics(currentRound, approx.logNormEstimate, annealingParameters)
      val roundTime = System.out.popIndent.watch.elapsed(TimeUnit.MILLISECONDS)
      writer(MonitoringOutput.roundTimings).write(
        Column.round -> currentRound,
        Column.isAdapt -> (currentRound < nRounds - 1),
        TidySerializer.VALUE -> roundTime
      )
      results.flushAll
    }
  }
  
  def reportRoundStatistics(int roundIndex, double logNormEstimate, List<Double> annealingParams) {
    val rPair = Column.round -> roundIndex
    
    writer(MonitoringOutput.logNormalizationConstantProgress).printAndWrite(
      rPair,
      TidySerializer.VALUE -> logNormEstimate
    )
    
    val annealingParamTabularWriter = writer(MonitoringOutput.annealingParameters) 
    val isAdapt = Column.isAdapt -> (roundIndex < nRounds - 1)
    for (var int i = 0; i < annealingParams.size(); i++) {
      val c = Column.chain -> i
      annealingParamTabularWriter.write(isAdapt, rPair, c,
        Pair.of(TidySerializer.VALUE, annealingParams.get(i)));
    }
  }
  
  def UserSpecified updateSchedule(List<Double> previousAnnealingParams, List<Double> incrementalLogWeightSDs, int nSMCItersForNextRound, int roundIndex) {
    val xs = Doubles::toArray(previousAnnealingParams)
    val ys = cumulativeSDs(incrementalLogWeightSDs, previousAnnealingParams)
    val spline = Spline.createMonotoneCubicSpline(xs, ys) as MonotoneCubicSpline
    reportLambdaFunctions(spline, nSMCItersForNextRound, roundIndex)
    val updated = EngineStaticUtils::fixedSizeOptimalPartition(spline, nSMCItersForNextRound)
    return new UserSpecified(updated)
  }
  
  def void reportLambdaFunctions(MonotoneCubicSpline cumulativeLambdaEstimate, int nSMCItersForNextRound, int roundIndex) {
    val rPair = Column.round -> roundIndex
    val isAdapt = Column.isAdapt -> (roundIndex < nRounds - 1)
    for (var int i = 1; i < PT._lamdbaDiscretization; i++) {
      val beta = (i as double) / (PT._lamdbaDiscretization as double)
      val betaReport = Column.beta -> beta
      writer(MonitoringOutput.cumulativeLambda).write(
        rPair, isAdapt, betaReport, 
        TidySerializer.VALUE -> cumulativeLambdaEstimate.value(beta)
      )
      writer(MonitoringOutput.lambdaInstantaneous).write(
        rPair, isAdapt, betaReport, 
        TidySerializer.VALUE -> SplineDerivatives.derivative(cumulativeLambdaEstimate, beta)
      );
    }
    val Lambda = cumulativeLambdaEstimate.value(1.0)
    writer(MonitoringOutput.globalLambda).printAndWrite(
      rPair,
      TidySerializer.VALUE -> Lambda
    );
    val prediction = (nSMCItersForNextRound ** 2) * Math::log(2.0) / (Lambda ** 2)
    writer(ISCMOutput::predictedResamplingInterval).printAndWrite(
      Column.round -> (roundIndex+1),
      TidySerializer.VALUE -> prediction
    )
  }
  
  def double [] cumulativeSDs(List<Double> SDs, List<Double> annealingParams) {
    val double [] result = newDoubleArrayOfSize(SDs.size + 1)
    val max = SDs.filter[Double.isFinite(it)].max
    for (var int i = 1; i < result.length; i++) {
      var sd = SDs.get(i-1);
      if (i == 1 && useExtrapolationForLeftPoint) {
        if (!resamplingTriggeredRejuvenation)
          throw new RuntimeException("This approximation may catastrophically fail without post-resampling rejuvenation when severe particle degeneracy occurs.")
        // SD{V} at beta = 0 is not guaranteed to exist
        // for now, just extrapolate the next end point...
        val old = SDs.get(i-1)
        if (i+1 < result.length) {
          val delta_height = SDs.get(i) - SDs.get(i+1)
          sd = Math::max(0, SDs.get(i) + delta_height)
          System.out.println("1st order interpolation for left point: " + sd + " instead of " + old)
        } else {
          sd = SDs.get(i)
          System.out.println("0th order interpolation for left point: " + sd + " instead of " + old)
        }
      }
      if (Double.isInfinite(sd)) {
        System.err.println("Warning: SD[incr W]=infinity in beta in [" + annealingParams.get(i-1) + "," + annealingParams.get(i) + ") -- for schedule cumulative SD using instead max+1=" + (max+1))
        sd = max + 1
      }
      result.set(i, result.get(i-1) + sd)
    }
    return result
  }
  
  override setSampledModel(SampledModel model) {
    super.setSampledModel(model)
    this.model = model;
  }
  
  
  override void recordPropagationStatistics(int iteration, double nextTemp, double ess, double logNorm) {
    writer(ISCMOutput::multiRoundPropagation).write(
      Column::round -> currentRound,
      iterationColumn -> iteration,
      annealingParameterColumn -> nextTemp,
      essColumn -> ess,
      logNormalizationColumn -> logNorm
    );
  }
  
  int prevResamplingIter = 0
  double prevResamplingAnnealingParam = 0.0 
  override void recordResamplingStatistics(int iteration, double temperature, double logNormalization) {
    writer(ISCMOutput::multiRoundResampling).printAndWrite(
      Column::round -> currentRound,
      iterationColumn -> iteration,
      annealingParameterColumn -> temperature,
      logNormalizationColumn -> logNormalization,
      ISCMColumns::deltaIterations -> (iteration - prevResamplingIter),
      ISCMColumns::deltaAnnealingParameter -> (temperature - prevResamplingAnnealingParam)
    )
    prevResamplingIter = iteration
    prevResamplingAnnealingParam = temperature
  }
  

  // TODO (NB: some of these might slow things down quite a bit, e.g. recordLogWeights)
  override void recordRelativeVarZ(String estimatorName, double logRelativeVarZ) {}
  override void recordLogWeights(double [] weights, double temperature) {}
  override void recordAncestry(int iteration, List<Integer> ancestors, double temperature) {}
  
  // see also PT.MonitoringOutput, using the latter as much as possible for consistency
  static enum ISCMOutput { budget, multiRoundPropagation, multiRoundResampling, predictedResamplingInterval }
  
  static enum ISCMColumns { deltaIterations, deltaAnnealingParameter }
  
  def TabularWriter writer(Object output)
  {
    return results.child(Runner.MONITORING_FOLDER).getTabularWriter(output.toString());
  }
}