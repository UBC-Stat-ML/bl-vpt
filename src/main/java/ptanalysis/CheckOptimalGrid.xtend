package ptanalysis

import blang.inits.Arg
import blang.inits.experiments.Experiment
import ptanalysis.GridOptimizer.OptimizationOptions
import blang.inits.DefaultValue

class CheckOptimalGrid extends Experiment {
  @Arg Energies energies 
  @Arg int nGrids
  
  @Arg  @DefaultValue("false") 
  boolean reversible = false
  
  override run() {
    val optimizer = new GridOptimizer(energies, reversible, 1)
    optimizer.useExpressObjective
    optimizer.coarseToFineOptimize(nGrids - 2, new OptimizationOptions)
    println("optimizedExpressPr = " + optimizer.expressProbability)
    println("optimizedRejPr = " + optimizer.rejuvenationPr)
    for (i : 0 ..< (nGrids - 1)) {
      val area = optimizer.area(optimizer.grid.get(i), optimizer.grid.get(i+1))
      results.getTabularWriter("area").write(
        "i" -> i,
        "left" -> optimizer.grid.get(i),
        "right" -> optimizer.grid.get(i+1),
        "area" -> area)
    }
    optimizer.initializeToEquiArea(nGrids)
    println("equiAreaExpressPr = " + optimizer.expressProbability)
    println("equiAreaRejPr = " + optimizer.rejuvenationPr)
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}