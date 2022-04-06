package ptbm

import blang.runtime.SampledModel
import blang.core.RealDistribution


import static blang.types.StaticUtils.fixedReal
import blang.distributions.Normal
import blang.core.RealVar
import bayonet.math.NumericalUtils

class StaticUtils {
  
  //// To promote to blang.type.StaticUtils
  
  def static VariationalReal unconstrainedLatentReal() {
    return new VariationalReal
  }

  
  /**
   * Soft plus i.e. soft version of "positive part" or max(0, x)
   */
  def static double softplus(double x) { 
    if (x >= 15.0) return x
    val result = Math::log1p(Math::exp(x))
    return Math::max(result, NumericalUtils::THRESHOLD)
  }
  def static double softplus(RealVar x) { softplus(x.doubleValue) }
  
  //// internal stuff
  
  def static variationalRealSamplers(SampledModel model) {
    model.posteriorInvariantSamplers.filter(VariationalRealSampler)
  }
  
  def static setVariationalActive(SampledModel model, boolean active) {
    for (sampler : model.variationalRealSamplers)
      sampler.variable.paused = !active
  }
  
  def static setVariationalApproximation(SampledModel [] copies, AllSummaryStatistics allStats) {
    for (copy : copies) 
      for (sampler : copy.variationalRealSamplers) {
        val id = sampler.variable.identifier
        val stats = allStats.values.get(id)
        val approx = normal(stats.mean, stats.variance)
        sampler.variable.variational = approx
      }
  }
  
  def static RealDistribution normal(double mean, double variance) {
    Normal::distribution(fixedReal(mean), fixedReal(variance))
  }
}