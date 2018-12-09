package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg
import blang.inits.DefaultValue
import org.apache.commons.math3.exception.TooManyIterationsException

class RejuvenationScalings extends Experiment {
  
  @Arg
  Energies energies 
  
  @Arg @DefaultValue("500")
  int maxGridSize = 500
  
  override run() {
    val writer = results.getTabularWriter("output")
    val x1optimization = results.getTabularWriter("x1optimization")
    val optimalGrid = results.getTabularWriter("optimalGrids")
    for (target : (1..9).map[it as double/10.0]) {
      println("Started target " + target)
      for (reversible : #[true, false]) {
        val optimizer = new GridOptimizer(energies, reversible, 1)
        try {
          optimizer.initializeViaTargetSwapAcceptProbability(target, maxGridSize)
          val curWriter =             writer.child("reversible", reversible).child("nChains", optimizer.grid.size).child("targetAccept", target)
          val curOptWriter =  x1optimization.child("reversible", reversible).child("nChains", optimizer.grid.size).child("targetAccept", target)
          val curGridWriter =    optimalGrid.child("reversible", reversible).child("nChains", optimizer.grid.size).child("targetAccept", target)
          curWriter.write(
            "method" -> "fromTargetAccept",
            "rejuvenationPr" -> optimizer.rejuvenationPr) 
          
          println("optimize fromTargetAccept")
          optimizer.optimize
          curWriter.write(
            "method" -> "optimizeFromTargetAccept",
            "rejuvenationPr" -> optimizer.rejuvenationPr) 
          optimizer.outputGrid(curGridWriter.child("method", "optimizeFromTargetAccept"))
            
          optimizer.initializedToUniform(optimizer.grid.size)
          curWriter.write(
            "method" -> "uniform",
            "rejuvenationPr" -> optimizer.rejuvenationPr) 
          optimizer.outputGrid(curGridWriter.child("method", "uniform"))
            
          println("optimize optimizeFromUniform")
          optimizer.optimize
          curWriter.write(
            "method" -> "optimizeFromUniform",
            "rejuvenationPr" -> optimizer.rejuvenationPr) 
          optimizer.outputGrid(curGridWriter.child("method", "optimizeFromUniform"))
           
          println("x1")
          val x1Optimized = GridOptimizer::optimizeX1(energies, reversible, optimizer.grid.size, curOptWriter)
          if (x1Optimized !== null) { // when n chains = 2
            curWriter.write(
              "method" -> "X1Move",
              "rejuvenationPr" -> x1Optimized.rejuvenationPr) 
            x1Optimized.outputGrid(curGridWriter.child("method", "X1Move"))
          }
        } catch (TooManyIterationsException tmi) {
          System.err.println("Too many iterations for target " + target + ", reversible=" + reversible)
        }
      }
    }
  } 
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}