package transports

import org.eclipse.xtend.lib.annotations.Data
import xlinear.Matrix

import static extension xlinear.MatrixExtensions.*
import bayonet.math.NumericalUtils

@Data
class TransportProblem {
  val Matrix cost  // n-by-m matrix
  val Matrix [] marginals // n-vector, m-vector
  
  new (Matrix cost, Matrix firstMarginal, Matrix secondMarginal) {
    if (cost.nRows !== firstMarginal.nEntries || 
        cost.nCols !== secondMarginal.nEntries || 
        !firstMarginal.vector || 
        !secondMarginal.vector)
        throw new RuntimeException
    NumericalUtils::checkIsClose(firstMarginal.sum, 1.0)
    NumericalUtils::checkIsClose(secondMarginal.sum, 1.0)
    this.cost = cost
    this.marginals = newArrayOfSize(2)
    this.marginals.set(0, firstMarginal)
    this.marginals.set(1, secondMarginal)
  }
}