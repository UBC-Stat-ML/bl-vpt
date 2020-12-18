package transports

import org.eclipse.xtend.lib.annotations.Data
import xlinear.Matrix

import static extension xlinear.MatrixExtensions.*
import bayonet.math.NumericalUtils

@Data
class Plan {
  val TransportProblem problem
  val Matrix joint
  val double cost
   
  new(TransportProblem problem, Matrix joint) {
    NumericalUtils::checkIsClose(1.0, joint.sum)
    if (joint.nRows !== problem.cost.nRows || joint.nCols !== problem.cost.nCols)
      throw new RuntimeException
    this.problem = problem
    this.joint = joint
    StaticUtils::checkMarginals(joint,           problem.marginals.get(0))
    StaticUtils::checkMarginals(joint.transpose, problem.marginals.get(1))
    this.cost = StaticUtils::cost(joint, problem.cost)
  }
}