package ptbm

import java.util.Map
import java.util.LinkedHashMap
import blang.runtime.SampledModel
import static extension ptbm.StaticUtils.*
import org.eclipse.xtend.lib.annotations.Accessors
import blang.inits.experiments.ExperimentResults
import static opt.Optimizer.Files.*
import static opt.Optimizer.Fields.*
import  static blang.inits.experiments.tabwriters.TidySerializer.VALUE
import opt.Optimizer.Fields

class AllSummaryStatistics {
  public val Map<VariableIdentifier, MeanVarSummaries> values = new LinkedHashMap
  @Accessors(PUBLIC_GETTER) var n = 0L
  
  // warning: changes the state of copies (reset stats)
  def getAndResetStatistics(SampledModel [] models) {
    for (copy : models) 
      for (variationalSampler : copy.variationalRealSamplers) 
        add(variationalSampler)
  }
  
  private def add(VariationalRealSampler sampler) {
    val contents = sampler.getAndResetStatistics
    val key = sampler.variable.identifier
    val previous = values.get(key)
    if (previous !== null)
      contents.combine(previous)
    n = Math::max(n, contents.count)
    values.put(key, contents)
  }
  
  override toString() {
    '''
    «FOR entry : values.entrySet»
    «entry.key» : mean=«entry.value.mean» var=«entry.value.variance»
    «ENDFOR»
    '''
  }
  
  def report(ExperimentResults results, int iterIdx, boolean isFinal, double budget) {
    results.getTabularWriter(optimizationPath.toString).child(iter, iterIdx).child("isFinal", isFinal).child(Fields.budget, budget) => [
      var d = 0
      for (entry : values.entrySet) {
        write(
          dim -> d++,
          name -> (entry.key.toString + "_MEAN"),
          VALUE -> entry.value.mean
        )
        write(
          dim -> d++,
          name -> (entry.key.toString + "_SOFTPLUS_VARIANCE"),
          VALUE -> entry.value.variance.inv_softplus
        )
      }
    ]
  }
  
  
}