package iscm

import bayonet.distributions.Random
import blang.System
import blang.engines.internals.EngineStaticUtils
import blang.engines.internals.PosteriorInferenceEngine
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
import blang.inits.GlobalArg
import blang.inits.experiments.ExperimentResults
import blang.inits.experiments.tabwriters.TabularWriter
import blang.inits.experiments.tabwriters.TidySerializer
import blang.runtime.Runner
import blang.runtime.SampledModel
import blang.runtime.internals.objectgraph.GraphAnalysis
import com.google.common.primitives.Doubles
import java.util.List
import blang.engines.internals.factories.PT.Column
import blang.engines.internals.factories.PT.MonitoringOutput

class ISCM implements PosteriorInferenceEngine { 
  
  @GlobalArg public ExperimentResults results = new ExperimentResults();
  
  @Arg
  public SCM scm = new SCM
   
  @Arg  @DefaultValue("5")
  public int nRounds = 5;
  
  @Arg                       @DefaultValue("20")
  public int initialNumberOfSMCIterations = 20;
  
  SampledModel model;
  
  override performInference() {
    var numberOfSMCIterations = initialNumberOfSMCIterations;
    scm.estimateFullZFunction = true;
    var TemperatureSchedule schedule = new FixedTemperatureSchedule() => [ nTemperatures = initialNumberOfSMCIterations ]
    for (r : 0 ..< nRounds) {
      System.out.indentWithTiming("Round(" + (r+1) + "/" + nRounds + ")") 
      scm.temperatureSchedule = schedule
      val streams = Random.parallelRandomStreams(scm.random, scm.nParticles)
      scm.results = results.child("round-" + r)
      val approx = scm.getApproximation(scm.initialize(model, streams), 1.0, model, streams, false)
      
      // increase number of particles, temperatures
      if (scm.nResamplingRounds == 0) 
        numberOfSMCIterations *= 2
      else {
        numberOfSMCIterations = Math::ceil(numberOfSMCIterations * Math::sqrt(2.0)) as int
        scm.nParticles        = Math::ceil(scm.nParticles        * Math::sqrt(2.0)) as int
      }
      
      // update schedule
      schedule = updateSchedule(scm.annealingParameters, scm.energySDs, numberOfSMCIterations, r)
      
      scm.random = streams.get(0)
      
      reportRoundStatistics(r, approx.logNormEstimate, scm.annealingParameters)
      System.out.popIndent()
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
  
  def UserSpecified updateSchedule(List<Double> previousAnnealingParams, List<Double> energySDs, int nSMCItersForNextRound, int roundIndex) {
    val xs = Doubles::toArray(previousAnnealingParams)
    val ys = cumulativeSDs(energySDs, previousAnnealingParams)
    val spline = Spline.createMonotoneCubicSpline(xs, ys) as MonotoneCubicSpline
    reportLambdaFunctions(spline, roundIndex)
    val updated = EngineStaticUtils::fixedSizeOptimalPartition(spline, nSMCItersForNextRound)
    return new UserSpecified(updated)
  }
  
  def void reportLambdaFunctions(MonotoneCubicSpline cumulativeLambdaEstimate, int roundIndex) {
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
  }
  
  def double [] cumulativeSDs(List<Double> SDs, List<Double> annealingParams) {
    val double [] result = newDoubleArrayOfSize(SDs.size + 1)
    for (var int i = 1; i < result.length; i++) {
      result.set(i, result.get(i-1) + SDs.get(i-1) * (annealingParams.get(i) - annealingParams.get(i-1)));
    }
    return result
  }
  
  override check(GraphAnalysis analysis) {
    scm.check(analysis)
  }
  
  override setSampledModel(SampledModel model) {
    scm.sampledModel = model
    this.model = model;
  }
  
  def TabularWriter writer(MonitoringOutput output)
  {
    return results.child(Runner.MONITORING_FOLDER).getTabularWriter(output.toString());
  }
}