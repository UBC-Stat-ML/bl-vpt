package ptanalysis

import java.util.ArrayList

import org.apache.commons.math3.analysis.UnivariateFunction;
import org.apache.commons.math3.optim.MaxEval;
import org.apache.commons.math3.optim.nonlinear.scalar.GoalType;
import org.apache.commons.math3.optim.univariate.BrentOptimizer;
import org.apache.commons.math3.optim.univariate.SearchInterval;
import org.apache.commons.math3.optim.univariate.UnivariateObjectiveFunction;
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import org.apache.commons.math3.analysis.solvers.PegasusSolver

@Data class GridOptimizer {
  val SwapPrs swapPrs
  val boolean reversible
  val List<Double> grid = new ArrayList
  
  int maxIterations = 100
  
  def void fromUniform(int nChains) {
    grid.clear
    // initialize with equally spaced say
    val increment = 1.0 / (nChains - 1.0)
    for (i : 0 ..< nChains) 
      this.grid.add(i * increment)
  }
  
  def void fromTargetAccept(double alpha) {
    grid.clear
    var currentParam = 0.0
    grid.add(currentParam)
    while (currentParam < 1.0) {
      currentParam = nextParam(currentParam, alpha) 
      grid.add(currentParam)     
    }
  }
  
  def private double nextParam(double current, double alpha) {
    if (swapPrs.between(current, 1.0) > alpha) return 1.0
    val leftBound = current
    val rightBound = 1.0
    val UnivariateFunction objective = [
      swapPrs.between(current, it) - alpha
    ]
    val solver = new PegasusSolver()
    return solver.solve(10_000, objective, leftBound, rightBound)
  }
  
  def void optimize() {
    val lastIter = rejuvenationPr
    for (iter : 0 .. maxIterations) {
      for (i : 1..< grid.size - 1)
        optimize(i)
      if (Math.abs(lastIter - rejuvenationPr) < 0.001)
        return
    }
  }
  
  def void optimize(int gridPointIndex) {
    if (gridPointIndex === 0 || gridPointIndex == grid.size - 1)
      throw new RuntimeException("Cannot move extreme grid points")
    val leftBound = grid.get(gridPointIndex - 1)
    val rightBound = grid.get(gridPointIndex + 1)
    val init = grid.get(gridPointIndex)
    val UnivariateFunction objective = [
      grid.set(gridPointIndex, it)
      return rejuvenationPr
    ]
    val optimizer = new BrentOptimizer(1e-10, 1e-10);
    val interval = new SearchInterval(leftBound, rightBound, init)
    val result = optimizer.optimize(
      GoalType.MAXIMIZE, 
      new UnivariateObjectiveFunction(objective), 
      interval, 
      new MaxEval(100)).point
    grid.set(gridPointIndex, result)
  }
  
  def double rejuvenationPr() { 
    val acceptPrs = new ArrayList<Double>
    for (i : 0 ..< grid.size - 1)
      acceptPrs.add(swapPrs.between(grid.get(i), grid.get(i+1)))
    val mc = new TemperatureProcess(acceptPrs, reversible)
    return new AbsorptionProbabilities(mc).absorptionProbability(mc.initialState, mc.absorbingState(1))
  } 
}