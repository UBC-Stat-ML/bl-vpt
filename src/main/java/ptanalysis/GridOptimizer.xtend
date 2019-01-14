package ptanalysis

import java.util.ArrayList

import org.apache.commons.math3.analysis.UnivariateFunction;
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
import blang.inits.DefaultValue
import blang.inits.Arg
import java.util.Collections
import org.apache.commons.math3.optim.univariate.UnivariatePointValuePair
import org.apache.commons.math3.optim.MaxEval
import org.apache.commons.math3.analysis.integration.SimpsonIntegrator

/**
 * See optimize()
 */
class GridOptimizer {
  
  //// Data needed for optimization
  val Energies energies
  val boolean reversible
  val int nHotChains // setting to > 1 corresponds to a X1 sampler
  
  def void coarseToFineOptimize(
    int nIntermediateChains, 
    OptimizationOptions options
  ) {
    if (nIntermediateChains < 0) throw new RuntimeException
    if (nIntermediateChains == 0) {
      return
    }
    var currentNIntermediates = 1
    initializedToUniform(2 + currentNIntermediates)
    while (currentNIntermediates < nIntermediateChains) {
      currentNIntermediates = Math.min(nIntermediateChains, 2*currentNIntermediates)
      // create a new refinement by starting from the old one
      val newGrid = new ArrayList(grid)
      var nAdded = 0
      val nToAdd = currentNIntermediates - (grid.size - 2)
      for (var int i = 1; nAdded < nToAdd; i++) {
        val left = grid.get(i)
        newGrid.add(left)
        nAdded++
      }
      initialize(newGrid)
      optimize(options)
    }
  }
  
  def area(double left, double right) {
    (new SimpsonIntegrator(1e-5, 1e-10, 3, 64)).integrate(
      1_000_000, 
      [energies.lambda(it)], 
      left, right
    )
  }
  
  def void initializeToEquiArea(int n) {
    val search = QuantileSearch::fromDensity([energies.lambda(it)], 0.0, 1.0, n * 100)
    initialize(search.quantiles(n - 1)) 
  }
  
  new (Energies energies, boolean reversible, int nHotChains) {
    this.energies = energies
    this.reversible = reversible
    this.nHotChains = nHotChains
  }
  
  //// Variable
  @Accessors(PUBLIC_GETTER)
  val List<Double> grid = new ArrayList(#[0.0, 1.0])
  
  static class OptimizationOptions {
    @Arg @DefaultValue("20")
    int maxIterations = 20
    
    @Arg @DefaultValue("1e-5")
    double  tolerence = 1e-5
  }
  
  /**
   * Main purpose of this class: maximize the probability of 
   * hitting the room temperature from the hot chain (vs collapsing 
   * back to the prior/hot chain). 
   * Equivalent to fraction of samples coming from new initialization 
   * in the parallel setting.
   */
  def void optimize(OptimizationOptions options) {
    var lastIter = criterion.apply
    for (iter : 0 .. options.maxIterations) {
      for (i : 1..< grid.size - 1)
        optimize(i)
      val current = criterion.apply
      if (Math.abs(lastIter - current) < options.tolerence) {
        return
      }
      lastIter = current
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
  
  def static GridOptimizer optimizeX1(Energies swapPrs, boolean reversible, int totalNChains, OptimizationOptions options) {
    optimizeX1(swapPrs, reversible, totalNChains, options, null)
  }
  def static GridOptimizer optimizeX1(Energies energies, boolean reversible, int totalNChains, OptimizationOptions options, TabularWriter writer) {
    var max = Double::NEGATIVE_INFINITY
    var GridOptimizer argMax = null
    for (nHotChains : 1 ..< (totalNChains - 1)) { // at least 3 levels, to avoid numerical problems
      val current = new GridOptimizer(energies, reversible, nHotChains) 
      current.coarseToFineOptimize(totalNChains - nHotChains - 1, options)
      val pr = current.criterion.apply
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
   * Number of grid points including 0.0 and 1.0 but ignoring 
   * the prior replicates.
   */
  def void initializedToUniform(int nGridPoints) {
    if (nGridPoints <= 1) throw new RuntimeException
    grid.clear
    // initialize with equally spaced say
    val increment = 1.0 / (nGridPoints - 1.0)
    for (i : 0 ..< nGridPoints) 
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
    Collections.sort(grid)
    if (grid.get(0) != 0.0 || grid.get(grid.size - 1) != 1.0)
      throw new RuntimeException
    checkAndRepairFirstInterval
  }
  
  /**
   * Approximation for first interval is less numerically robust,
   * so if get a problem, just reduce the first interval to a spacing that behaves well.
   */
  private def void checkAndRepairFirstInterval() {
    if (nHotChains == 1) {
      return // only needed because of X1Approximations
    }
    if (grid.size === 2) 
      throw new RuntimeException
    firstSpacingLimit = 1.0
    while (!ok(firstSpacingLimit)) 
      firstSpacingLimit /= 2.0
    if (grid.get(1) > firstSpacingLimit)
      grid.set(1, firstSpacingLimit / 2.0)
  }
  var firstSpacingLimit = 1.0
  
  private def boolean ok(double point) {
    if (nHotChains == 1) return true
    val accept = X1Approximations::acceptPr(energies as NormalEnergies, point, nHotChains)
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
    if (leftBound == rightBound)
      return
    val UnivariateFunction objective = [
      grid.set(gridPointIndex, it)
      return criterion.apply
    ]
    
    // The problem can be non-convex, so try search from both end points and the old value
    val old = grid.get(gridPointIndex)
    val fromLeft  = optimize(leftBound, rightBound, leftBound, objective)
    val fromRight = optimize(leftBound, rightBound, rightBound, objective)
    val fromOld   = optimize(leftBound, rightBound, old, objective)
    
    var UnivariatePointValuePair argmax = null
    var double max = Double::NEGATIVE_INFINITY
    for (candidate : #[fromLeft, fromRight, fromOld])
      if (candidate.value >= max) {
        max = candidate.value
        argmax = candidate
      }
    grid.set(gridPointIndex, argmax.point)
  }
  
  def private UnivariatePointValuePair optimize(double leftBound, double rightBound, double init, UnivariateFunction objective) {
    val optimizer = new BrentOptimizer(1e-5, 1e-5)
    val interval = new SearchInterval(leftBound, rightBound, init)
    return optimizer.optimize(
      GoalType.MAXIMIZE, 
      new UnivariateObjectiveFunction(objective), 
      interval,
      new MaxEval(100))
  }
  
  public var ()=> double criterion = [rejuvenationPr]
  
  def void useExpressObjective() {
    criterion = [expressProbability]
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
  
  def double expressProbability() {
    var product = 1.0
    for (i : 0 ..< grid.size - 1)
      product *= acceptPr(i)
    return product
  }
  
  def double acceptPr(int i) {
    if (nHotChains <= 0) throw new RuntimeException
    val cur = grid.get(i)
    val nxt = grid.get(i+1)
    if (nxt == cur)
      return 1.0
    if (nxt <= cur) 
      throw new RuntimeException
    if (i > 0 || nHotChains == 1)
      return energies.swapAcceptPr(cur, nxt)
    else 
      return X1Approximations::acceptPr(energies as NormalEnergies, grid.get(1), nHotChains)
  }
  
  def static void main(String [] args) {
    // Faithful:
//    val file = new File("/Users/bouchard/experiments/ptanalysis-nextflow/work/cc/e0d3e1eb94fcf7a5d92dc66a581ff1/inference/samples/energy.csv")
     // always No = 0.49 !! also No >> MC here
    
    // Challenger:
    //val file = new File("/Users/bouchard/experiments/ptanalysis-nextflow/work/8d/033467f86195e533434ac75cc3651f/multiBenchmark/work/2e/1474f7155162b20efcde820b5f660a/results/all/2018-12-06-14-47-38-Q0oAfuOe.exec/samples/energy.csv")
    // No about 30%, No < MC
    // area under curve not too big either
    
    // Ising:
     //val file = new File("/Users/bouchard/experiments/ptanalysis-nextflow/work/d9/f82fec315c940490b1f07e82c917f3/multiBenchmark/work/fd/e86c35763d1efc3dcc9b90fac5cb2b/results/all/2018-12-09-11-18-39-04XggwEZ.exec/samples/energy.csv")
    // very accurate
    
//    val fullE = SwapStaticUtils::preprocessedEnergies(file)
//    val energies = new Energies(file)
    
//    println(energies.moments.keySet)
    
//    val params = new ArrayList(fullE.keySet).sort
//    for (j : 1 ..< 100) {
//      val param = params.get(j)
//      println(param)
//      println("\tNo = " + energies.swapAcceptPr(0.0, param))
//      println("\tMC = " + SwapStaticUtils::estimateSwapPr(0.0, param, fullE.get(0.0), fullE.get(param)))
//      println("\tAT = " + (1.0 - param * energies.lambda(param)))
//    }
    
//    if (true) {return}
//    
//    for (n : #[2, 4, 8, 16]) {
//      val go = new GridOptimizer(energies, false, n)
//      go.initializedToUniform(300)
////      go.grid.set(1, 1e-30)
//      println(go.grid.get(1) + "," + go.acceptPr(0) + "," + go.acceptPr(1) + "," + go.acceptPr(2) + "," + go.rejuvenationPr)
//    }


    /*
     * This experiment below is misleading: mass looks very large close to zero but this is probably an 
     * artifact of the linear interpolation being bad there: indeed all the bad mass is contained before the 
     * first grid point in the approximation
     */

//    var right = 1.0
//    val f = [double x | energies.lambda(x)]
//    for (i : 0 ..< 200) {
//      val integrator = new SimpsonIntegrator
//      val left = right / 2.0
//      val value = integrator.integrate(100000, f, left, right)
//      println("" + left + " \t" + right + " \t" + value)
//      right = left
//    }
  }
}