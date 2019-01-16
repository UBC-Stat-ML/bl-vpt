package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg
import org.apache.commons.math3.analysis.integration.SimpsonIntegrator

class CheckAsymptoticTime extends Experiment {
  @Arg Energies energies
  @Arg Paths paths
  
  override run() {
    
    /*
     * Notation:
     * 
     * R_N - fraction of rounds in MC where new colour seen for 1st time
     *  NB: <= 1/2 since new prior samples (colour) promoted only 1/2 of iterations
     * 
     * C_N - convection time
     *  NB: >= 2N
     * 
     * P_N - probability that a prior sample will hit posterior before prior
     *  NB: in (0, 1)
     * 
     * N - # chains
     * 
     * Relations:
     * 
     *   N
     * _____ ~ R_N 
     *  C_N
     * 
     * 2 R_N ~ P_N
     * 
     */
        
    // Here we are trying to approximate \tilde C_N/N in various ways
    
    val fromMC = paths.cycleTimeStatistics.getMean / paths.nChains
    println("fromMCOutput = " + fromMC)
    
    val optimizer = new GridOptimizer(energies, false, 1)
    val integral = println(optimizer.area(0.0, 1.0))
    val asymptotic = 2.0 + 2.0 * integral  // argg.. this works if instead = 2.0 + integral
    println("asymptotic = " + asymptotic) 
    
    for (i : 2 .. 20) {
      val size = (2 ** i) as int
      optimizer.initializedToUniform(size)
      val p = optimizer.rejuvenationPr
      println("fromLinAlg (" + size + ") = " + (2.0 / p))
    }
  }
  
//  def asymptotic() {
//    val integral = 
////    (new SimpsonIntegrator(1e-6, 1e-10, 3, 64)).integrate(
////      1_000_000, 
////      [energies.lambda(it)], 
////      0.0, 1.0
////    )
//    return 2.0 + 4.0 * integral
//  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}