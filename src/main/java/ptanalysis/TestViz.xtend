package ptanalysis

import java.io.File
import blang.inits.experiments.Experiment
import viz.core.Viz

class TestViz extends Experiment {
  def static void main(String [] args) {
    Experiment::start(args)
  }
  
  override run() {
    val files = #[
      "/Users/bouchard/experiments/ptanalysis-nextflow/work/cc/e0d3e1eb94fcf7a5d92dc66a581ff1/inference/samples/energy.csv",
      "/Users/bouchard/experiments/ptanalysis-nextflow/work/8d/033467f86195e533434ac75cc3651f/multiBenchmark/work/2e/1474f7155162b20efcde820b5f660a/results/all/2018-12-06-14-47-38-Q0oAfuOe.exec/samples/energy.csv",
      "/Users/bouchard/experiments/ptanalysis-nextflow/work/d9/f82fec315c940490b1f07e82c917f3/multiBenchmark/work/fd/e86c35763d1efc3dcc9b90fac5cb2b/results/all/2018-12-09-11-18-39-04XggwEZ.exec/samples/energy.csv",
      "/Users/bouchard/experiments/ptanalysis-nextflow/work/08/d1585c19caa5826384656b9aa8d123/multiBenchmark/work/dc/38e545d5f351820256f11b61048b60/results/all/2019-01-14-11-48-13-c2mGFFau.exec/samples/energy.csv"
    ].map[new File(it)]
    
    val names = #["faithful", "challenger", "ising", "discrete"]
    
    for (problemIndex : 0 ..< files.size)
      for (mode : SwapPrsViz.ApproximationMode.values) {
        new SwapPrsViz(
          files.get(problemIndex), 
          mode, 
          Viz::fixHeight(300)
        ).output(results.getFileInResultFolder("" + names.get(problemIndex) + "_" + mode + ".pdf"))
      }
  }
}