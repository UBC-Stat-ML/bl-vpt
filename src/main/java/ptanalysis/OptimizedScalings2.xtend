package ptanalysis

import java.io.File
import blang.inits.experiments.Experiment

class OptimizedScalings2 extends Experiment {
  
  override run() {
    val writer = results.getTabularWriter("output")
    val prs = new ApproxAcceptPrs(new File("/Users/bouchard/experiments/blang-mixture-tempering/work/55/1fdcf66051e25fba133d3be2af06d2/results/all/2018-11-13-22-28-19-LplqtyMI.exec/samples/energy.csv"))
    for (target : (1..8).map[it as double/10.0]) {
      for (reversible : #[true, false]) {
        println("reversible = " + reversible)
        val optimizer = new GridOptimizer(prs, reversible)
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