package ptanalysis

import org.apache.commons.math3.distribution.NormalDistribution
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import java.util.List
import java.io.File
import java.util.TreeMap
import java.util.Map
import blang.inits.DesignatedConstructor
import blang.inits.Input
import blang.inits.Arg
import blang.inits.DefaultValue
import org.apache.commons.math3.special.Erf
import bayonet.math.NumericalUtils

class Energies { 
  val TreeMap<Double, SummaryStatistics> moments
  
  @Arg(description = "Create artificial replicates of state space for asymptotic analysis purpose")          
                @DefaultValue("1")
  public var int nReplicates = 1
  
  /**
   * Estimate the acceptance probability between the two annealing parameters 
   * using a normal approximation of the energies, and where the means and variances 
   * of the energies are interpolated from Monte Carlo estimates.
   */
  def double swapAcceptPr(double param1, double param2) {
    acceptPr(param1, param2, meanEnergy(param1), meanEnergy(param2), varianceEnergy(param1), varianceEnergy(param2)) 
  }
  
  @DesignatedConstructor
  new(@Input String path) { this(new File(path)) }
  new(File f) { this(moments(SwapStaticUtils::loadEnergies(f))) }
  new(TreeMap<Double, SummaryStatistics> moments) {
    this.moments = moments
    // check it's valid
    if (!moments.containsKey(0.0) || !moments.containsKey(1.0)) 
      throw new RuntimeException
  }
  
  def double meanEnergy(double annealParam) {     nReplicates * interpolate(annealParam, [mean]) }
  def double varianceEnergy(double annealParam) { nReplicates * interpolate(annealParam, [variance]) }
  
  def private double interpolate(double annealParam, (SummaryStatistics) => double stat /* mean or variance */) {
    check(annealParam)
    if (moments.keySet.contains(annealParam)) return stat.apply(moments.get(annealParam))
    // interpolate using boundary at left and right (floor and ceil)
    val prev = moments.floorEntry(annealParam)
    val next = moments.ceilingEntry(annealParam)
    // linear interpolation for annealParam b/w x0 and x1 where x0 -> y0, x1 -> y1
    val x0 = prev.key
    val x1 = next.key
    val y0 = stat.apply(prev.value)
    val y1 = stat.apply(next.value)
    val slope = (y1 - y0) / (x1 - x0)
    return y0 + slope * (annealParam - x0)
  }
  
  def check(double p) {
    if (p < 0 || p > 1) throw new RuntimeException
  }
  
  //////
  
  def static TreeMap<Double,SummaryStatistics> moments(Map<Double,List<Double>> samples) {
    val result = new TreeMap<Double,SummaryStatistics>
    for (entry : samples.entrySet) 
      result.put(entry.key, new SummaryStatistics() => [for (sample : entry.value) addValue(sample)])
    return result
  }
  
  def static double acceptPr(double annealParam1, double annealParam2, double mean1, double mean2, double variance1, double variance2) {
    if (mean1 === mean2 && variance1 === variance2) return 1.0
    val deltaAnneal = annealParam2 - annealParam1
    return acceptPr(deltaAnneal * (mean2 - mean1), deltaAnneal * deltaAnneal * (variance1 + variance2))
  }
  
  /**
   * Approximation of E(min{1, e^A}) for A ~ Normal(m, variance) from 
   * Roberts et al. 1997, Proposition 2.4
   */
  def private static double acceptPr(double m, double variance) {
    if (variance <= 0.0) throw new RuntimeException
    val s = Math.sqrt(variance)
    val a = Math.exp(m + s*s/2.0)
    val b = STD_NORMAL.cumulativeProbability(-s - m/s)
    val result = STD_NORMAL.cumulativeProbability(m/s) + a * b
    if ((Double.isInfinite(a) && b === 0) || (Double.isInfinite(b) && a === 0)) {
      // when both the mean and variance are large, numerical problem can occur
      // then use the bound E(min{1, e^A}) >= P(A >= 0)
      val cdf = new NormalDistribution(m, s).cumulativeProbability(0.0)
      if (Double.isNaN(cdf) || Double.isInfinite(cdf))
        throw new RuntimeException
      return 1.0 - cdf
      //throw new RuntimeException("estimate=" + (1.0 - estimate.cumulativeProbability(1.0)) + "m=" + m + ", var=" + variance + ", Math.exp(m + s*s/2.0)=" + Math.exp(m + s*s/2.0) + ", cdf(x)=" + STD_NORMAL.cumulativeProbability(-s - m/s) + ", x=" + (-s - m/s)) // get 0 + INF * 0.0 = NaN for large variances. 
    } else if (Double.isNaN(result))
      throw new RuntimeException
    else return result
  }
  val static STD_NORMAL = new NormalDistribution(0.0, 1.0)
  
//  def static double logErf(double x) {
//    val t = 1.0 / (1.0 + p * x)
//    val poly = a1 * t + a2 * t * t + a3 * t * t * t
//    val prod = Math.log(poly) - x * x
//    return NumericalUtils.logAdd(0.0, -prod)
//  }
//  
  static val p  = 0.47047
  static val a1 = 0.3480242
  static val a2 = -0.0958798
  static val a3 = 0.7478556
  def static void main(String [] args) {
    for (i : 0 .. 10) {
      val x = -Math.pow(2, i)
      val t = 1.0 / (1.0 + p * x)
      val approx = 1.0 - (a1 * t + a2 * t * t + a3 * t * t * t) * Math.exp(- x * x)
      val exact = Erf.erf(x)
      println(approx)
      println(exact)
      println(Math.abs(approx - exact) / exact)
      println("--")
    }
  }
}