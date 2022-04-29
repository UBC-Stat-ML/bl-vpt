package ptbm

import blang.mcmc.Sampler
import bayonet.distributions.Random
import blang.mcmc.internals.SamplerBuilderContext
import blang.mcmc.SampledVariable
import blang.core.WritableRealVar
import blang.mcmc.ConnectedFactor
import java.util.List
import blang.core.LogScaleFactor
import blang.mcmc.RealSliceSampler
import blang.core.RealVar
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import ptanalysis.StdNormalProposalMH

class VariationalRealSampler implements Sampler {
  
  @SampledVariable
  public VariationalReal variable
  
  @ConnectedFactor
  protected List<LogScaleFactor> numericFactors
  
  Sampler sampler
  RealVar annealingParam
  MeanVarSummaries statistics
  
  def MeanVarSummaries getAndResetStatistics() {
    val result = statistics
    statistics = new MeanVarSummaries
    return result
  }
  
  override execute(Random rand) {
    sampler.execute(rand)
    if (annealingParam.doubleValue === 1.0)
      statistics.add(variable.doubleValue)
  }
  
  public static boolean useMH = false
  
  override boolean setup(SamplerBuilderContext context) {
    sampler = if (useMH) StdNormalProposalMH::build(variable, numericFactors) else RealSliceSampler::build(variable, numericFactors)
    annealingParam = context.annealingParameter
    statistics = new MeanVarSummaries
    return true
  }
  
}
