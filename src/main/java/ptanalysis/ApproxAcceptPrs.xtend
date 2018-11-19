package ptanalysis

import org.apache.commons.math3.distribution.NormalDistribution
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import java.util.List
import java.util.ArrayList
import java.io.File
import java.util.TreeMap
import java.util.Map

class ApproxAcceptPrs { 
  val TreeMap<Double, SummaryStatistics> moments
  
  new(File f) { this(moments(AcceptPrs::loadEnergies(f))) }
  new(TreeMap<Double, SummaryStatistics> moments) {
    this.moments = moments
    // check it's valid
    if (!moments.containsKey(0.0) || !moments.containsKey(1.0)) 
      throw new RuntimeException
  }
  
  /**
   * Estimate the acceptance probability between the two annealing parameters 
   * using a normal approximation of the energies, and where the means and variances 
   * of the energies are interpolated from Monte Carlo estimates.
   */
  def double estimate(double param1, double param2) {
    acceptPr(param1, param2, mean(param1), mean(param2), variance(param1), variance(param2)) 
  }
  
  def double mean(double annealParam) { interpolate(annealParam, [mean]) }
  def double variance(double annealParam) { interpolate(annealParam, [variance]) }
  
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
  
  val static STD_NORMAL = new NormalDistribution(0.0, 1.0)
  def private static double acceptPr(double m, double variance) {
    if (variance <= 0.0) throw new RuntimeException
    val s = Math.sqrt(variance)
    val result = STD_NORMAL.cumulativeProbability(m/s) + Math.exp(m + s*s/2.0) * STD_NORMAL.cumulativeProbability(-s - m/s)
    if (Double.isNaN(result)) throw new RuntimeException // get 0 + INF * 0.0 = NaN for large variances. 
    else return result
  }
  
  def static void main(String [] args) {
    val energies = AcceptPrs::loadEnergies(new File("/Users/bouchard/experiments/blang-mixture-tempering/work/55/1fdcf66051e25fba133d3be2af06d2/results/all/2018-11-13-22-28-19-LplqtyMI.exec/samples/energy.csv"))
    val moments = moments(energies)
    val annealParams = new ArrayList(energies.keySet)
    for (i : 0 ..< annealParams.size) {
      val p1 = annealParams.get(0)
      val p2 = annealParams.get(i)
      val mc = AcceptPrs::estimateSwapPr(p1, p2, energies.get(p1), energies.get(p2))
      val approx = ApproxAcceptPrs::acceptPr(p1, p2, moments.get(p1).mean, moments.get(p2).mean, moments.get(p1).variance, moments.get(p2).variance) 
      println('''mc=«mc» approx=«approx» mean=«moments.get(p2).mean» var=«moments.get(p2).variance»''')
    }
  }
}