package ptbm

import blang.engines.internals.Spline.MonotoneCubicSpline
import blang.engines.internals.factories.PT
import blang.inits.Arg
import blang.inits.DefaultValue

import static opt.Optimizer.Files.*
import static opt.Optimizer.Fields.*
import opt.Optimizer.Fields
import  static blang.inits.experiments.tabwriters.TidySerializer.VALUE

import blang.System;

import static extension ptbm.StaticUtils.*
import blang.runtime.SampledModel
import java.util.Arrays
import bayonet.distributions.Random
import blang.engines.internals.factories.PT.Round

class OptPT extends PT {
  
  @Arg @DefaultValue("100")
  public int minSamplesForVariational = 100
  
  public PT fixedRefPT = null
  
  @Arg            @DefaultValue("true")
  public boolean useFixedRefPT = true
  
  var budget = 0.0
  
  override reportRoundStatistics(Round round) {
    budget += round.nScans * nPassesPerScan * nChains * (if (useFixedRefPT) 2.0 else 1.0)
    super.reportRoundStatistics(round)
  }
  
  override moveKernel(double nPasses) {
    super.moveKernel(nPasses)
    if (useFixedRefPT) {
      fixedRefPT.moveKernel(nPasses)
    }
  }
  
  override swapAndRecordStatistics(int scanIndex) {
    super.swapAndRecordStatistics(scanIndex)
    if (useFixedRefPT) {
      fixedRefPT.swapAndRecordStatistics(scanIndex)
      if (scanIndex % 2 == 1) {
        // note we index so that the room temp chain is at 0
        // hence for odd swaps the room temp chain is not involved in swaps
        // hence these are the iterations where we want to do swaps b/w 
        // the variational and fixed ref chains
        swapFixedRefAndVariational()
      }
    }
  }
  
  def swapFixedRefAndVariational() {
    val initially_variational = this.states.get(0)
    val initially_fixedRef = fixedRefPT.states.get(0)
    
    // enable/disable variational
    initially_variational.setVariationalActive(false)
    initially_fixedRef.   setVariationalActive(true)
    
    this.states.set(0,       initially_fixedRef)
    fixedRefPT.states.set(0, initially_variational)
  }
  
  int iterIdx = 0
  override MonotoneCubicSpline adapt(boolean finalAdapt) { 
    val stats = AllSummaryStatistics.getAndResetStatistics(states)
    if (stats.n > minSamplesForVariational) {
      System.out.println('''Updating variational reference («stats.values.keySet.size» variables)''')
      states.setVariationalApproximation(stats)
      stats.report(results, iterIdx, finalAdapt, budget)
      results.getTabularWriter(optimizationMonitoring.toString).child(iter, iterIdx).child("isFinal", finalAdapt).child(Fields.budget, budget) => [
        write(
          name -> "Rejection",
          VALUE -> Arrays.stream(swapAcceptPrs).map[1.0 - mean].mapToDouble[it].sum
        )
      ]
    }
    iterIdx++
    
    if (useFixedRefPT) {
      fixedRefPT.adapt(finalAdapt) 
    }
    
    return super.adapt(finalAdapt)
  }
  
  override void recordSamples(int scanIndex) {
    super.recordSamples(scanIndex)
    // not using those at the moment but could later...
    // if (useFixedRefPT) fixedRefPT.recordSamples(scanIndex)
  }
  
  override void reportAcceptanceRatios(Round round) {
    super.reportAcceptanceRatios(round)
    if (useFixedRefPT) {
      fixedRefPT.reportAcceptanceRatios(round)
    }
  }
  
  override void reportParallelTemperingDiagnostics(Round round) {
    System.out.indentWithTiming("Variational chains:")
    super.reportParallelTemperingDiagnostics(round)
    System.out.popIndent
    if (useFixedRefPT) {
      System.out.indentWithTiming("Fixed reference chains:")
      fixedRefPT.reportParallelTemperingDiagnostics(round)
      System.out.popIndent
    }
  }
  
  override void setSampledModel(SampledModel m) {
    for (entry : m.objectsToOutput.entrySet) {
      val key = entry.key
      val value = entry.value
      if (value instanceof VariationalReal) {
        value.identifier = new VariableIdentifier(key)
      }
    }
    super.setSampledModel(m)
    if (useFixedRefPT) {
      fixedRefPT = new PT
      setOptions(fixedRefPT)
      System.out.println("Initializing fixed reference chain.")
      val copy = m.duplicate
      copy.setVariationalActive(false)
      fixedRefPT.setSampledModel(copy)
    }
  }
  
  def setOptions(PT fpt) {
    fpt.nThreads = this.nThreads
    fpt.ladder = this.ladder
    fpt.nChains = this.nChains
    fpt.usePriorSamples = this.usePriorSamples
    fpt.reversible = this.reversible
    
    // might not be needed but just in case design changes later
    fpt.nScans = this.nScans 
    fpt.adaptFraction = this.adaptFraction
    fpt.nPassesPerScan = this.nPassesPerScan
    fpt.thinning = this.thinning
    fpt.targetAccept = this.targetAccept
    fpt.scmInit = this.scmInit
    fpt.initialization = this.initialization
    fpt.logNormalizationEstimator = this.logNormalizationEstimator
    fpt.statisticRecordedMaxChainIndex = this.statisticRecordedMaxChainIndex
    
    // output statistics in subdirectory
    fpt.results = this.results.child("fixedReferencePT")
    
    // split randoms
    val randoms = Random::parallelRandomStreams(this.random, 2)
    this.random = randoms.get(0)
    fpt.random = randoms.get(1)

  }
  
}