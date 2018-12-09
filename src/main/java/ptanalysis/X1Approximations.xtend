package ptanalysis

import org.eclipse.xtend.lib.annotations.Data

import static java.lang.Math.log
import static java.lang.Math.exp
import static java.lang.Math.sqrt
import org.apache.commons.math3.distribution.NormalDistribution
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class X1Approximations {
  
  def static double acceptPr(Energies energies, double lukeWarmBeta, int nPriorReplica) {
    return acceptPr(
      energies.meanEnergy(0.0), energies.varianceEnergy(0.0), 
      energies.meanEnergy(lukeWarmBeta), energies.varianceEnergy(lukeWarmBeta),
      lukeWarmBeta,
      nPriorReplica
    )
  }
  
  def static double acceptPr(
    double priorEnergyMean,    double priorEnergyVariance, 
    double lukeWarmEnergyMean, double lukeWarmEnergyVariance, 
    double lukeWarmBeta,
    int nPriorReplica
  ) {
    val onePrior = potential(priorEnergyMean, priorEnergyVariance, lukeWarmBeta)
    val allPriors = approximateSum(onePrior, nPriorReplica)
    val lukeWarmPotential = potential(lukeWarmEnergyMean, lukeWarmEnergyVariance, lukeWarmBeta)
    val p0 = allPriors
    val p1 = lukeWarmPotential
    val ratio = new LogitNormal(p0.mu - p1.mu, p0.sigma2 + p1.sigma2)
    return ratio.mean
  }
  
  def static LogNormal potential(double energyMean, double energyVariance, double beta) {
    new LogNormal(- beta * energyMean, beta * beta * energyVariance)
  }
  
  public static var qmcEpsilon = 0.001
  
  @Data static class LogitNormal {
    val double mu
    val double sigma2

    def double mean() {
      val normal = new NormalDistribution(mu, sqrt(sigma2))
      val stats = new SummaryStatistics
      for (var double p = qmcEpsilon; p < 1.0; p += qmcEpsilon) {
        val normalSample = normal.inverseCumulativeProbability(p)
        val logitSample = 1.0 / (1.0 + exp(-normalSample))
        stats.addValue(logitSample)
      }
      return stats.mean
    }
  }
  
  @Data static class LogNormal {
    val double mu
    val double sigma2
    def double mean() {
      return exp(mu + sigma2 / 2.0)
    }
    def double variance() {
      return mean * mean * (exp(sigma2) - 1.0)
    }
  }
  
  def static LogNormal fromMeanVariance(double mean, double variance) {
    val sigma2 = log(variance / mean / mean + 1)
    val mu = log(mean) - sigma2 * sigma2 / 2.0
    return new LogNormal(mu, sigma2)
  }
  
  def static LogNormal approximateSum(LogNormal distribution, int nReplica) {
    val mean = distribution.mean * nReplica
    val variance = distribution.variance * nReplica
    return fromMeanVariance(mean, variance)
  }
  
  def static double logit(double x) {
    log(x) - log(1.0-x)
  }
  
  private new() {}
}