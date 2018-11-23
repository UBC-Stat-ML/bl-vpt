package ptanalysis

import org.junit.Test
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import java.util.TreeMap

class ApproxAcceptTest {
  @Test
  def void test() {
    val stats0 = new SummaryStatistics => [
//      addValue(0.0)
      addValue(0.0)
      addValue(0.5)
      addValue(0.1)
    ]
//    println(stats0)
    val stats0_4 = new SummaryStatistics => [
//      addValue(60.0)
      addValue(0.0)
      addValue(-0.5)
      addValue(0.99)
    ]
//    println(stats0_4)
    val stats1 = new SummaryStatistics => [
//      addValue(0.0)
      addValue(-100.5)
      addValue(-0.5)
      addValue(0.99)
    ]
//    println(stats1)
    val map = new TreeMap<Double,SummaryStatistics> => [
      put(0.0, stats0)
      put(0.4, stats0_4)
      put(1.0, stats1)
    ]
    val approx = new NormalEnergySwapPrs(map)
    for (p : (0..8).map[it/10.0]) { // at 0.9 and 1.0 gets variance too large
      println("" + p + " mean " + approx.mean(p))
      println("" + p + " variance " + approx.variance(p))
      println(approx.between(0.0, p)) 
    }
  }
}