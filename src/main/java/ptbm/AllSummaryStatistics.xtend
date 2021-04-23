package ptbm

import java.util.Map
import java.util.LinkedHashMap
import blang.runtime.SampledModel
import static extension ptbm.StaticUtils.*
import org.eclipse.xtend.lib.annotations.Accessors

class AllSummaryStatistics {
  public val Map<VariableIdentifier, MeanVarSummaries> values = new LinkedHashMap
  @Accessors(PUBLIC_GETTER) var n = 0L
  
  new(SampledModel [] copies) {
    for (copy : copies) 
      for (variationalSampler : copy.variationalRealSamplers) 
        add(variationalSampler)
  }
  
  def add(VariationalRealSampler sampler) {
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
}