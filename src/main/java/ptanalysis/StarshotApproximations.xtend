package ptanalysis

import org.eclipse.xtend.lib.annotations.Data

import static java.lang.Math.log
import static java.lang.Math.exp
import static java.lang.Math.sqrt
import static java.lang.Math.PI
import static java.lang.Math.abs
import org.apache.commons.math3.analysis.integration.RombergIntegrator
import org.apache.commons.math3.distribution.NormalDistribution
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class StarshotApproximations {
  
  def static double acceptPr(NormalEnergySwapPrs normalEnergies, double lukeWarmBeta, int nPriorReplica) {
    return acceptPr(
      normalEnergies.mean(0.0), normalEnergies.variance(0.0), 
      normalEnergies.mean(lukeWarmBeta), normalEnergies.variance(lukeWarmBeta),
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
  public static boolean useQMC = true
  
  @Data static class LogitNormal {
    val double mu
    val double sigma2
    def double mean() {
      if (useQMC) mean_qmc else mean_numerical
    }
    def double mean_qmc() {
      val normal = new NormalDistribution(mu, sqrt(sigma2))
      val stats = new SummaryStatistics
      for (var double p = qmcEpsilon; p < 1.0; p += qmcEpsilon) {
        val normalSample = normal.inverseCumulativeProbability(p)
        val logitSample = 1.0 / (1.0 + exp(-normalSample))
        stats.addValue(logitSample)
      }
      return stats.mean
    }
    def double mean_numerical() {
      try {
      val area = integrateOnUnitInterval[x | density(x)]
      if (abs(1.0 - area) > 0.001)
        throw new RuntimeException("Should be close to one: " + area + " @mu=" + mu + ",sigma2=" + sigma2)
      return integrateOnUnitInterval[x | x * density(x)]
      } catch (Exception e) { throw new RuntimeException("error@mu=" + mu + ",sigma2=" + sigma2)}
    }
    def double density(double x) {
      val diff = (logit(x) - mu)
      val result = exp(- diff * diff / sigma2 / 2.0) / sqrt(sigma2 * 2.0 * PI) / x / (1.0 - x)
      if (Double::isNaN(result) || Double.isInfinite(result))
        return 0.0
      else
        return result
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
  
  def private static double integrateOnUnitInterval((Double) => double function) {
    return (new RombergIntegrator).integrate(10_000_000, function, 0.0, 1.0)
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