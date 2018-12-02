package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg

class RejuvenationScalings extends Experiment {
  
  @Arg
  Energies energies 
  
  override run() {
    val writer = results.getTabularWriter("output")
    val x1optimization = results.getTabularWriter("x1optimization")
    val optimalGrid = results.getTabularWriter("optimalGrids")
    for (target : (1..9).map[it as double/10.0]) {
      for (reversible : #[true, false]) {
        println("reversible = " + reversible)
        val optimizer = new GridOptimizer(energies, reversible, 1)
        optimizer.initializeViaTargetSwapAcceptProbability(target)
        println("nChains for target " + target + " is " + optimizer.grid.size)
        println("chain = " + optimizer.grid)
        val curWriter =             writer.child("reversible", reversible).child("nChains", optimizer.grid.size).child("targetAccept", target)
        val curOptWriter =  x1optimization.child("reversible", reversible).child("nChains", optimizer.grid.size).child("targetAccept", target)
        val curGridWriter =    optimalGrid.child("reversible", reversible).child("nChains", optimizer.grid.size).child("targetAccept", target)
        curWriter.write(
          "method" -> "fromTargetAccept",
          "rejuvenationPr" -> optimizer.rejuvenationPr) 
          
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
          
        optimizer.optimize
        curWriter.write(
          "method" -> "optimizeFromUniform",
          "rejuvenationPr" -> optimizer.rejuvenationPr) 
        optimizer.outputGrid(curGridWriter.child("method", "optimizeFromUniform"))
          
        val x1Optimized = GridOptimizer::optimizeX1(energies, reversible, optimizer.grid.size, curOptWriter)
        curWriter.write(
          "method" -> "X1Move",
          "rejuvenationPr" -> x1Optimized.rejuvenationPr) 
        x1Optimized.outputGrid(curGridWriter.child("method", "X1Move"))
      }
    }
  } 
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}