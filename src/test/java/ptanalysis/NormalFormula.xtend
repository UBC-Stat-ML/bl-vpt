package ptanalysis

import org.junit.Test
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import bayonet.distributions.Random
import org.junit.Assert

import static extension blang.distributions.Generators.*

class NormalFormula {
  
  @Test
  def void atchadeFormula() {
    val rand = new Random(1)
    atchadeFormula(-1.592826565208879E7, 8.591999846734327E17)
    for (i : 0 ..< 100) 
      atchadeFormula(rand.nextGaussian, rand.nextGaussian ** 2) 
  }
  
  def static void atchadeFormula(double m, double variance) {
    // mc version
    val mc = simpleMonteCarlo(new Random(1), 100_000) [
      Math.min(1.0, Math.exp(normal(m, variance)))
    ].mean
    Assert::assertEquals(
      println(Energies::acceptPr(m, variance)), 
      println(mc),
      mc * 0.01
    )
    println("---")
  }
  
  def static void main(String [] args) {
    val file = "/Users/bouchard/experiments/ptanalysis-nextflow/work/cc/e0d3e1eb94fcf7a5d92dc66a581ff1/inference/samples/energy.csv"
    val energies = new Energies(file)
    println(energies.swapAcceptPr(0.0, 1.0))
    println("for 0.0: " + energies.meanEnergy(0.0) + " " + energies.varianceEnergy(0.0))
    println("for 1.0: " + energies.meanEnergy(1.0) + " " + energies.varianceEnergy(1.0))
  }
  
  def static SummaryStatistics simpleMonteCarlo(Random rand, int nIterations, (Random) => double randomVariable) {
    val result = new SummaryStatistics
    for (i : 0 ..< nIterations) 
      result.addValue(randomVariable.apply(rand))
    return result
  }
}