package ptanalysis

import org.apache.commons.math3.distribution.NormalDistribution
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import java.util.LinkedHashMap
import java.util.List
import java.util.ArrayList
import java.io.File

class ApproxAcceptPr { 
  def static LinkedHashMap<Double,SummaryStatistics> moments(LinkedHashMap<Double,List<Double>> samples) {
    val result = new LinkedHashMap<Double,SummaryStatistics>
    for (entry : samples.entrySet) 
      result.put(entry.key, new SummaryStatistics() => [for (sample : entry.value) addValue(sample)])
    return result
  }
  
  def static double acceptPr(double annealParam1, double annealParam2, double mean1, double mean2, double variance1, double variance2) {
    val deltaAnneal = annealParam2 - annealParam1
    return acceptPr(deltaAnneal * (mean2 - mean1), deltaAnneal * deltaAnneal * (variance1 + variance2))
  }
  
  val static STD_NORMAL = new NormalDistribution(0.0, 1.0)
  def private static double acceptPr(double m, double variance) {
    val s = Math.sqrt(variance)
    STD_NORMAL.cumulativeProbability(m/s) + Math.exp(m + s*s/2.0) * STD_NORMAL.cumulativeProbability(-s - m/s)
  }
  
  def static void main(String [] args) {
    val energies = AcceptPrs::preprocessedEnergies(new File("/Users/bouchard/experiments/blang-mixture-tempering/work/55/1fdcf66051e25fba133d3be2af06d2/results/all/2018-11-13-22-28-19-LplqtyMI.exec/samples/energy.csv"))
    val moments = moments(energies)
    val annealParams = new ArrayList(energies.keySet)
    for (i : 0 ..< annealParams.size) {
      val p1 = annealParams.get(0)
      val p2 = annealParams.get(i)
      val mc = AcceptPrs::estimateSwapPr(p1, p2, energies.get(p1), energies.get(p2))
      val approx = ApproxAcceptPr::acceptPr(p1, p2, moments.get(p1).mean, moments.get(p2).mean, moments.get(p1).variance, moments.get(p2).variance) 
      println('''«mc» «approx»''')
    }
  }
}