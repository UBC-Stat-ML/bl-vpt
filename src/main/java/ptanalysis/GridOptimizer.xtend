package ptanalysis

import java.util.ArrayList

import org.apache.commons.math3.analysis.UnivariateFunction;
import org.apache.commons.math3.optim.MaxEval;
import org.apache.commons.math3.optim.nonlinear.scalar.GoalType;
import org.apache.commons.math3.optim.univariate.BrentOptimizer;
import org.apache.commons.math3.optim.univariate.SearchInterval;
import org.apache.commons.math3.optim.univariate.UnivariateObjectiveFunction;
import java.util.List
import blang.inits.experiments.tabwriters.TabularWriter
import java.util.Collection
import org.eclipse.xtend.lib.annotations.Accessors
import org.apache.commons.math3.exception.TooManyIterationsException
import org.apache.commons.math3.analysis.solvers.PegasusSolver

/**
 * See optimize()
 */
class GridOptimizer {
  
  //// Data needed for optimization
  val Energies energies
  val boolean reversible
  val int nHotChains // setting to > 1 corresponds to a X1 sampler
  
  new (Energies energies, boolean reversible, int nHotChains) {
    this.energies = energies
    this.reversible = reversible
    this.nHotChains = nHotChains
  }
  
  //// Variable
  @Accessors(PUBLIC_GETTER)
  val List<Double> grid = new ArrayList(#[0.0, 1.0])
  
  /** Maximum number of iteration to perform the optimization. */
  @Accessors(PUBLIC_SETTER, PUBLIC_GETTER) 
  var int maxIterations = 100
  
  /**
   * Main purpose of this class: maximize the probability of 
   * hitting the room temp from the hot chain (vs collapsing 
   * back to the prior/hot chain). 
   * Equivalent to fraction of samples coming from new initialization 
   * in the parallel setting.
   */
  def void optimize() {
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
    optimizeX1(swapPrs, reversible, totalNChains, null, false)
  }
  def static GridOptimizer optimizeX1(Energies energies, boolean reversible, int totalNChains, TabularWriter writer, boolean earlyStop) {
    var max = Double::NEGATIVE_INFINITY
    var GridOptimizer argMax = null
    var List<Double> lastGrid
    for (nHotChains : 1 .. (totalNChains - 1)) {
      val current = new GridOptimizer(energies, reversible, nHotChains) 
      if (nHotChains == 1)
        current.initializedToUniform(totalNChains - nHotChains + 1) 
      else {
        lastGrid.remove(1)
        current.initialize(lastGrid)
      }
      current.optimize
      lastGrid = new ArrayList(current.grid)
      val pr = current.rejuvenationPr
      if (writer !== null) writer.write(
        "nHotChains" -> nHotChains,
        "rejuvenationPr" -> pr
      )
      if (pr > max) {
        max = pr
        argMax = current
      } else if (earlyStop) 
        return argMax
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
    checkAndRepairFirstInterval
  }
  
  /**
   * Initialize such that the accept probabilities is the given 
   * input parameter
   * 
   * @param alpha Target accept rate
   */
  def void initializeViaTargetSwapAcceptProbability(double targetSwapAcceptPr, int maxGridSize) {
    if (targetSwapAcceptPr <= 0.0 || targetSwapAcceptPr >= 1.0) throw new RuntimeException
    grid.clear
    var currentParam = 0.0
    grid.add(currentParam)
    while (currentParam < 1.0) {
      currentParam = nextParam(currentParam, targetSwapAcceptPr) 
      grid.add(currentParam)  
      if (grid.size > maxGridSize)
        throw new TooManyIterationsException(maxGridSize)
    }
    if (grid.size <= 1) throw new RuntimeException
    checkAndRepairFirstInterval
  }
  
  /**
   * Copies, sorts and checks end points are 0.0 and 1.0. 
   */
  def void initialize(Collection<Double> initGrid) {
    grid.clear
    grid.addAll(initGrid)
    grid.sort
    if (grid.get(0) != 0.0 || grid.get(grid.size - 1) != 1.0)
      throw new RuntimeException
    checkAndRepairFirstInterval
  }
  
  /**
   * Approximation for first interval is less numerically robust,
   * so if get a problem, just reduce the first interval to a spacing that behaves well.
   */
  private def void checkAndRepairFirstInterval() {
    firstSpacingLimit = 1.0
    while (!ok(firstSpacingLimit)) 
      firstSpacingLimit /= 2.0
    if (grid.get(1) > firstSpacingLimit)
      grid.set(1, firstSpacingLimit / 2.0)
  }
  var firstSpacingLimit = 1.0
  
  private def boolean ok(double point) {
    if (nHotChains == 1) return true
    val accept = X1Approximations::acceptPr(energies, point, nHotChains)
    return accept >= 0.0 && accept <= 1.0
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
    val next = grid.get(gridPointIndex + 1)
    val rightBound = 
      if (gridPointIndex === 1)
        Math::min(grid.get(gridPointIndex + 1), firstSpacingLimit)
      else
        next
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
    for (i : 0 ..< grid.size - 1)  
      acceptPrs.add(acceptPr(i))
    val mc = new TemperatureProcess(acceptPrs, reversible)
    return AbsorptionProbabilities::compute(mc) 
  } 
  
  def double acceptPr(int i) {
    if (nHotChains <= 0) throw new RuntimeException
    val cur = grid.get(i)
    val nxt = grid.get(i+1)
    if (nxt <= cur) throw new RuntimeException
    if (i > 0 || nHotChains == 1)
      return energies.swapAcceptPr(cur, nxt)
    else 
      return X1Approximations::acceptPr(energies, grid.get(1), nHotChains)
  }
}