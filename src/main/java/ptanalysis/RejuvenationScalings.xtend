package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg

class RejuvenationScalings extends Experiment {
  
  @Arg
  SwapPrs swapPrs 
  
  override run() {
    val writer = results.getTabularWriter("output")
    for (target : (1..9).map[it as double/10.0]) {
      for (reversible : #[true, false]) {
        println("reversible = " + reversible)
        val optimizer = new GridOptimizer(swapPrs, reversible)
        optimizer.fromTargetAccept(target)
        println("nChains for target " + target + " is " + optimizer.grid.size)
        println("chain = " + optimizer.grid)
        val curWriter = writer
          .child("reversible", reversible)
          .child("nChains", optimizer.grid.size)
          .child("targetAccept", target)
        
        curWriter.write(
          "method" -> "fromTargetAccept",
          "rejuvenationPr" -> optimizer.rejuvenationPr) 
        optimizer.optimize
        curWriter.write(
          "method" -> "optimizeFromTargetAccept",
          "rejuvenationPr" -> optimizer.rejuvenationPr) 
        optimizer.fromUniform(optimizer.grid.size)
        curWriter.write(
          "method" -> "uniform",
          "rejuvenationPr" -> optimizer.rejuvenationPr) 
        optimizer.optimize
        curWriter.write(
          "method" -> "optimizeFromUniform",
          "rejuvenationPr" -> optimizer.rejuvenationPr) 
      }
    }
  } 
  
  def static void main(String [] args) {
    Experiment::start(args)
  }
}