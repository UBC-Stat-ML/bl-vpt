package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg
import blang.inits.DefaultValue
import org.apache.commons.math3.exception.TooManyIterationsException
import ptanalysis.GridOptimizer.OptimizationOptions
import java.util.List

class RejuvenationScalings extends Experiment {
  
  @Arg
  public Energies energies 
  
  @Arg @DefaultValue("1000")
  public int maxGridSize = 1000
  
  @Arg @DefaultValue("true")
  public boolean byTargetRate = true
  
  @Arg @DefaultValue("0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9")
  List<Double> indices = #[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
  
  @Arg 
  OptimizationOptions optimizationOptions = new OptimizationOptions
  
  override run() {
    val writer = results.getTabularWriter("output")
    val x1optimization = results.getTabularWriter("x1optimization")
    val optimalGrid = results.getTabularWriter("optimalGrids")
    for (index : indices) {
      println("Started iteration index " + index)
      for (reversible : #[true, false]) {
        val optimizer = new GridOptimizer(energies, reversible, 1)
        try {
          var curWriter =             writer.child("reversible", reversible)
          var curOptWriter =  x1optimization.child("reversible", reversible)
          var curGridWriter =    optimalGrid.child("reversible", reversible)
          val int size = if (byTargetRate) {
            optimizer.initializeViaTargetSwapAcceptProbability(index as Double, maxGridSize)
            
            curWriter = curWriter.child("nChains", optimizer.grid.size).child("targetAccept", index)
            curOptWriter = curOptWriter.child("nChains", optimizer.grid.size).child("targetAccept", index)
            curGridWriter = curGridWriter.child("nChains", optimizer.grid.size).child("targetAccept", index)
            
            curWriter.write(
              "method" -> "targetAccept",
              "rejuvenationPr" -> optimizer.rejuvenationPr)
            optimizer.outputGrid(curGridWriter.child("method", "targetAccept")) 
            
            println("optimize from targetAccept")
            optimizer.optimize(optimizationOptions)
            curWriter.write(
              "method" -> "optimizeFromTargetAccept",
              "rejuvenationPr" -> optimizer.rejuvenationPr) 
            optimizer.outputGrid(curGridWriter.child("method", "optimizeFromTargetAccept"))
            optimizer.grid.size
          } else {
            curWriter = curWriter.child("nChains", index)
            curOptWriter = curOptWriter.child("nChains", index)
            curGridWriter = curGridWriter.child("nChains", index)
            index.intValue
          }
            
          optimizer.initializedToUniform(size)
          curWriter.write(
            "method" -> "uniformGrid",
            "rejuvenationPr" -> optimizer.rejuvenationPr) 
          optimizer.outputGrid(curGridWriter.child("method", "uniformGrid"))
          
          println("optimize coarse to fine")
          optimizer.coarseToFineOptimize(optimizer.grid.size - 2, optimizationOptions)
          curWriter.write(
            "method" -> "optimizeCoarseToFine",
            "rejuvenationPr" -> optimizer.rejuvenationPr) 
          optimizer.outputGrid(curGridWriter.child("method", "optimizeCoarseToFine"))
           
          if (energies instanceof NormalEnergies) {
            println("x1")
            val x1Optimized = GridOptimizer::optimizeX1(energies, reversible, optimizer.grid.size, optimizationOptions,  curOptWriter)
            if (x1Optimized !== null) { // when n chains = 2
              curWriter.write(
                "method" -> "x1Move",
                "rejuvenationPr" -> x1Optimized.rejuvenationPr) 
              x1Optimized.outputGrid(curGridWriter.child("method", "x1Move"))
            }
          }
        } catch (TooManyIterationsException tmi) {
          System.err.println("Too many iterations for target " + index + ", reversible=" + reversible)
        }
      }
    }
  } 
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}