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
import blang.inits.experiments.tabwriters.TabularWriter

/**
 * See optimize()
 */
@Data class GridOptimizer {
  
  //// Data needed for optimization
  val Energies energies
  val boolean reversible
  val int nHotChains // setting to > 1 corresponds to a X1 sampler
  
  //// Variable
  val List<Double> grid = new ArrayList
  
  /** Maximum number of iteration to perform the optimization. */
  int maxIterations = 100
  
  /**
   * Main purpose of this class: maximize the probability of 
   * hitting the room temp from the hot chain (vs collapsing 
   * back to the prior/hot chain). 
   * Equivalent to fraction of samples coming from new initialization 
   * in the parallel setting.
   */
  def void optimize() {
    if (grid.empty) throw new RuntimeException("Call first an initializer (see initializeXXX)")
    val lastIter = rejuvenationPr
    for (iter : 0 .. maxIterations) {
      for (i : 1..< grid.size - 1)
        optimize(i)
      if (Math.abs(lastIter - rejuvenationPr) < 0.001)
        return
    }
  }
  
  def void outputGrid(TabularWriter writer) {
    for (i : 0 ..< grid.size)
      writer.write(
        "gridIndex" -> i,
        "annealParam" -> grid.get(i)
      )
  }
  
  //// Utility to optimize over number of hot chains as well
  
  def static GridOptimizer optimizeX1(Energies swapPrs, boolean reversible, int totalNChains) {
    optimizeX1(swapPrs, reversible, totalNChains, null)
  }
  def static GridOptimizer optimizeX1(Energies energies, boolean reversible, int totalNChains, TabularWriter writer) {
    var max = Double::NEGATIVE_INFINITY
    var GridOptimizer argMax = null
    for (nHotChains : 1 .. (totalNChains - 1)) {
      val current = new GridOptimizer(energies, reversible, nHotChains)
      current.initializedToUniform(totalNChains - nHotChains + 1) 
      current.optimize
      val pr = current.rejuvenationPr
      if (writer !== null) writer.write(
        "nHotChains" -> nHotChains,
        "rejuvenationPr" -> pr
      )
      if (pr > max) {
        max = pr
        argMax = current
      }
    }
    return argMax
  }
  
  //// A few different ways to initialize the optimizer
  
  /**
   * Initialize at equal spacings of the annealing parameters.
   */
  def void initializedToUniform(int nChains) {
    if (nChains <= 1) throw new RuntimeException
    grid.clear
    // initialize with equally spaced say
    val increment = 1.0 / (nChains - 1.0)
    for (i : 0 ..< nChains) 
      this.grid.add(i * increment)
  }
  
  /**
   * Initialize such that the accept probabilities is the given 
   * input parameter
   * 
   * @param alpha Target accept rate
   */
  def void initializeViaTargetSwapAcceptProbability(double targetSwapAcceptPr) {
    if (targetSwapAcceptPr <= 0.0 || targetSwapAcceptPr >= 1.0) throw new RuntimeException
    grid.clear
    var currentParam = 0.0
    grid.add(currentParam)
    while (currentParam < 1.0) {
      currentParam = nextParam(currentParam, targetSwapAcceptPr) 
      grid.add(currentParam)     
    }
    if (grid.size <= 1) throw new RuntimeException
  }
  
  /**
   * Used by fromTargetAccept to find a gap, started at current 
   * such that the accept pr to the other end is alpha. 
   * 
   * Return the other end point of the gap, which will be 
   * the next parameter in the grid
   * (i.e. NOT the length)
   */
  def private double nextParam(double current, double targetSwapAcceptPr) {
    if (energies.swapAcceptPr(current, 1.0) > targetSwapAcceptPr) return 1.0
    val leftBound = current
    val rightBound = 1.0
    val UnivariateFunction objective = [
      energies.swapAcceptPr(current, it) - targetSwapAcceptPr
    ]
    val solver = new PegasusSolver()
    return solver.solve(10_000, objective, leftBound, rightBound)
  }
  
  /**
   * Optimize a single grid separator.
   */
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
  
  /**
   * Compute the current value of the objective function, which 
   * is the hitting probability described in optimize()
   */
  def double rejuvenationPr() { 
    if (grid.get(0) !== 0.0 || grid.get(grid.size - 1) !== 1.0)
      throw new RuntimeException
    val acceptPrs = new ArrayList<Double>
    for (i : 0 ..< grid.size - 1) {
      // for the X1 move, we will assume first grid 
      val cur = grid.get(i)
      val nxt = grid.get(i+1)
      if (nxt <= cur) throw new RuntimeException
      acceptPrs.add(energies.swapAcceptPr(cur, nxt))
    }
    if (nHotChains <= 0) throw new RuntimeException
    if (nHotChains > 1) {
      val x1Approx = X1Approximations::acceptPr(energies, grid.get(1), nHotChains)
      if ((x1Approx >= 0.0 && x1Approx <= 1.0)) // guard against numerical instabilities
        acceptPrs.set(0, x1Approx)
    }
    val mc = new TemperatureProcess(acceptPrs, reversible)
    return new AbsorptionProbabilities(mc).absorptionProbability(mc.initialState, mc.absorbingState(1))
  } 
}