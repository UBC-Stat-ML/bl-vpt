package ptanalysis

import bayonet.distributions.Random
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class MCTest {
  
  interface ProbabilitySpace {
    def void next()
  }
  
  def static double E(ProbabilitySpace space, ()=>Double function) {
    val stats = new SummaryStatistics
    for (i : 0 .. 100_000) {
      space.next
      stats.addValue(function.apply)
    }
    return stats.mean
  }
  
  def static double P(ProbabilitySpace it, ()=>Boolean function) {
    E[if (function.apply) 1.0 else 0.0]
  }
  
  def static double Var(ProbabilitySpace it, ()=>Double function) {
    return E[function.apply ** 2] - E[function.apply] ** 2
  }
  
  def static double Covar(ProbabilitySpace it, ()=>Double var1, ()=>Double var2) {
    return E[var1.apply * var2.apply] - E(var1) * E(var2)
  }
  
  static class Simple implements ProbabilitySpace {
    var double X
    var double Y
    val rand = new Random(1)
    override next() {
      X = rand.nextDouble
      Y = 1.0 - X
    }
  }
  
  def static void main(String [] args) {
    new Simple => [
      println( E[ X + Y ] )
      println( P[ X < Y ] )
      println( Var[ X - Y ] )
    ]
  }
}