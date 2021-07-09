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
  
  override boolean setup(SamplerBuilderContext context) {
    sampler = RealSliceSampler::build(variable, numericFactors)
    annealingParam = context.annealingParameter
    statistics = new MeanVarSummaries
    return true
  }
  
}

/*
 * special variation factor
 * 
 * 
 * 
 * 
 * 
 * possible strategies
 * 
 * - still based on interpolation, etc
 * - 
 * 
 * models we want to test
 * 
 * existing:
 * 
 * - logistic
 * - copy number **
 * - ode **
 * - hierarchical model (rocket, vaccine)
 * - mixture (just doing
 * 
 * easy
 * 
 * - N school
 * - new logistics: sparse, other link functions, large p, large n, large p&n
 * - new ode (from bench paper)
 * - causality
 * - AR, ARIMA, etc
 * - spatial problem
 * - spline
 * - Stochastic volatility models
 * - more regression (G prior, other GLM, etc)
 * 
 * [ *** check out newly found list https://github.com/andrewcparnell/jags_examples/tree/master/R%20Code ]
 * 
 * interesting variational
 * 
 * - Ising with structured variation
 * - spike-and-slab
 * 
 * unknown variational
 * 
 * - tree
 * - mixture
 * 
 * 
 */