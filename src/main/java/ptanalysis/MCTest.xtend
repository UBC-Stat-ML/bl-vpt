package ptanalysis

import bayonet.distributions.Random
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class MCTest {
  
  public static var numberMonteCarloIterations = 10_000
  
  interface ProbabilitySpace {
    def void next()
  }
  
  def static double mcSE(ProbabilitySpace it, ()=>Double function) {
    SD(function) / Math::sqrt(numberMonteCarloIterations)
  }
  
  def static double E(ProbabilitySpace space, ()=>Double function) {
    val stats = new SummaryStatistics
    for (i : 0 ..< numberMonteCarloIterations) {
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
  
  def static double SD(ProbabilitySpace it, ()=>Double function) { Math::sqrt(Var(function))}
  
  def static double Covar(ProbabilitySpace it, ()=>Double var1, ()=>Double var2) {
    val e1 = E(var1)
    val e2 = E(var2)
    return E[(var1.apply - e1) * (var2.apply - e2)]
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