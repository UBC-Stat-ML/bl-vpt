package ptanalysis

import java.io.File
import blang.inits.experiments.Experiment

class OptimizedScalings extends Experiment {
  override run() {
    val writer = results.getTabularWriter("output")
    val prs = new ApproxAcceptPrs(new File("/Users/bouchard/experiments/blang-mixture-tempering/work/55/1fdcf66051e25fba133d3be2af06d2/results/all/2018-11-13-22-28-19-LplqtyMI.exec/samples/energy.csv"))
    for (nChains : 3..21) {
      for (reversible : #[true, false]) {
        val optimizer = new GridOptimizer(prs, reversible)
        for (iter : 0 .. 10) {
          optimizer.optimize
          writer.write(
            "reversible" -> reversible,
            "nChains" -> nChains,
            "iteration" -> iter,
            "rejuvenationPr" -> optimizer.rejuvenationPr
          )
        }
      }
    }
  }
   
  def static void main(String [] args) { 
    Experiment::start(args)
  }
}