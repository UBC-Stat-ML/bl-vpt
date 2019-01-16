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
  
  /*
   * In many cases the performance of all methods below is actually pretty close.
   * 
   * One e.g. where there is some diff: discrete model, 10 chains, get:
   * 
   * /Users/bouchard/w/ptanalysis/results/all/2019-01-15-15-25-31-NxLTiS8M.exec
   * 
      unifSpacingExpressPr = 0.6852677569001034
      unifSpacingRejPr = 0.7020608957561002
      optimizedExpressPr = 0.7384907202339527
      optimizedRejPr = 0.7623567011487391
      equiAreaExpressPr = 0.7130086163099612
      equiAreaRejPr = 0.7436546731093164
      executionMilliseconds : 148685
      outputFolder : /Users/bouchard/w/ptanalysis/results/all/2019-01-15-15-25-31-NxLTiS8M.exec
   * 
   * So here the equi-area method (71) beats unif spacings (69) but optimized beats everyone (74) 
   * 
   */
  
  override run() {
    val optimizer = new GridOptimizer(energies, reversible, 1)
    optimizer.useExpressObjective
    
    optimizer.initializedToUniform(nGrids)
    println("unifSpacingExpressPr = " + optimizer.expressProbability)
    println("unifSpacingRejPr = " + optimizer.rejuvenationPr)
    
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