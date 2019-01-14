package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg
import org.apache.commons.math3.analysis.integration.SimpsonIntegrator

class CheckAsymptoticTime extends Experiment {
  @Arg Energies energies
  @Arg Paths paths
  
  override run() {
    // path based
    
    val cycleTime = paths.cycleTimeStatistics.getMean
    println("fromMCOutput = " + (cycleTime / paths.nChains))
    
    val asymptotic = asymptotic()
    println("asymptotic = " + asymptotic) 
      // * 2 b/c computation for half vs full
      // / 2 b/c not taking account of odd-even
    
    val optimizer = new GridOptimizer(energies, false, 1)
    
    for (i : 2 .. 20) {
      optimizer.initializedToUniform((2 ** i) as int)
      println("fromLinAlg = " + 2.0 / optimizer.rejuvenationPr)
    }
  }
  
  def asymptotic() {
    val integral = (new SimpsonIntegrator(1e-5, 1e-10, 3, 64)).integrate(
      1_000_000, 
      [energies.lambda(it) * it], 
      0.0, 1.0
    )
    return 1.0 + 2.0 * integral
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}