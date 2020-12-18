package transports

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import org.eclipse.xtend.lib.annotations.Data
import org.apache.commons.math3.optim.linear.LinearObjectiveFunction
import bayonet.math.CoordinatePacker
import xlinear.Matrix
import org.apache.commons.math3.optim.linear.LinearConstraintSet
import org.apache.commons.math3.optim.linear.LinearConstraint
import java.util.ArrayList
import java.util.List
import org.apache.commons.math3.optim.linear.Relationship
import org.apache.commons.math3.optim.linear.NonNegativeConstraint

@Data
class SimplexSolver implements TransportSolver {
  
  new() {
    this.implementation = new org.apache.commons.math3.optim.linear.SimplexSolver()
  }
  
  val extension org.apache.commons.math3.optim.linear.SimplexSolver implementation
  
  override Plan solve(TransportProblem problem) {
    val CoordinatePacker index = new CoordinatePacker(#[problem.cost.nRows, problem.cost.nCols])
    
    val List<LinearConstraint> constraints = new ArrayList
    
    addMarginalConstraints(index, problem.marginals.get(0), constraints, false)
    addMarginalConstraints(index, problem.marginals.get(1), constraints, true)

    val result = optimize(
      new LinearObjectiveFunction(coefficients(index, problem.cost), 0.0), 
      new LinearConstraintSet(constraints),
      new NonNegativeConstraint(true)
    ).getPoint
    
    val joint = dense(problem.cost.nRows, problem.cost.nCols)
    for (r : 0 ..< problem.cost.nRows)
      for (c : 0 ..< problem.cost.nCols)
        joint.set(r, c, result.get(index.coord2int(r, c)))
    
    return new Plan(problem, joint)
  }

  def static void addMarginalConstraints(CoordinatePacker index, Matrix marginal, List<LinearConstraint> constraints, boolean transposed) {
    val otherDim = index.size / marginal.nEntries
    for (i : 0 ..< marginal.nEntries) { // i in 0 ..< n for first call
      val it = newDoubleArrayOfSize(index.size)
      for (j : 0 ..< otherDim) // j in 0 ..< m for first call
        set(if (transposed) index.coord2int(j, i) else index.coord2int(i, j), 1.0)
      constraints.add(new LinearConstraint(it, Relationship.EQ, marginal.get(i)))
    }
  }
  
  def static double [] coefficients(CoordinatePacker index, Matrix costs) {
    val it = newDoubleArrayOfSize(index.size)
    for (r : 0 ..< costs.nRows)
      for (c : 0 ..< costs.nCols)
        set(index.coord2int(r, c), costs.get(r, c))
    return it
  }
}