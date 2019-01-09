package ptanalysis

import org.junit.Test
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import java.util.TreeMap

class ApproxAcceptTest {
  @Test
  def void test() {
    val stats0 = new SummaryStatistics => [
      addValue(0.0)
      addValue(0.5)
      addValue(0.1)
    ]
    val stats0_4 = new SummaryStatistics => [
      addValue(0.0)
      addValue(-0.5)
      addValue(0.99)
    ]
    val stats1 = new SummaryStatistics => [
      addValue(-100.5)
      addValue(-0.5)
      addValue(0.99)
    ]
    val map = new TreeMap<Double,SummaryStatistics> => [
      put(0.0, stats0)
      put(0.4, stats0_4)
      put(1.0, stats1)
    ]
    val approx = new NormalEnergies(map)
    for (p : (0..8).map[it/10.0]) { // at 0.9 and 1.0 gets variance too large
      println("" + p + " mean " + approx.meanEnergy(p))
      println("" + p + " variance " + approx.varianceEnergy(p))
      println(approx.swapAcceptPr(0.0, p)) 
    }
  }
}