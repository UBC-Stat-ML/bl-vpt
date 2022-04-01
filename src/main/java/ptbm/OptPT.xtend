package ptbm

import blang.engines.internals.Spline.MonotoneCubicSpline
import blang.engines.internals.factories.PT
import blang.inits.Arg
import blang.inits.DefaultValue

import static opt.Optimizer.Files.*
import static opt.Optimizer.Fields.*
import opt.Optimizer.Fields
import  static blang.inits.experiments.tabwriters.TidySerializer.VALUE


import static extension ptbm.StaticUtils.*
import blang.runtime.SampledModel
import java.util.Arrays

class OptPT extends PT {
  
  @Arg @DefaultValue("100")
  public int minSamplesForVariational = 100
  
  var budget = 0.0
  
  override reportRoundStatistics(Round round) {
    budget += round.nScans * nPassesPerScan * nChains
    super.reportRoundStatistics(round)
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
    return super.adapt(finalAdapt)
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
  }
  
}