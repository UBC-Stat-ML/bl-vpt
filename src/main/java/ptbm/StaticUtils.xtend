package ptbm

import blang.runtime.SampledModel
import blang.core.RealDistribution


import static blang.types.StaticUtils.*
import blang.distributions.Normal

class StaticUtils {
  
  //// To promote to blang.type.StaticUtils
  
  def static VariationalReal unconstrainedLatentReal() {
    return new VariationalReal
  }
  
  //// internal stuff
  
  def static variationalRealSamplers(SampledModel model) {
    model.posteriorInvariantSamplers.filter(VariationalRealSampler)
  }
  
  def static setVariationalApproximation(SampledModel [] copies, AllSummaryStatistics allStats) {
    blang.System.out.indentWithTiming("Variational approximation")
    println(allStats)
    for (copy : copies) 
      for (sampler : copy.variationalRealSamplers) {
        val id = sampler.variable.identifier
        val stats = allStats.values.get(id)
        val approx = normal(stats.mean, stats.variance)
        sampler.variable.variational = approx
      }
    blang.System.out.popIndent
  }
  
  def static RealDistribution normal(double mean, double variance) {
    Normal::distribution(fixedReal(mean), fixedReal(variance))
  }
}