package transports

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import xlinear.Matrix
import xlinear.DenseMatrix
import bayonet.math.NumericalUtils
import org.eclipse.xtend.lib.annotations.Data
import bayonet.math.CoordinatePacker
import briefj.collections.UnorderedPair
import java.util.List

class StaticUtils {
  
  def static double intersectionSize(int [] s1, int [] s2) {
    var sum = 0.0
      for (v : 0 ..< s1.length)  
        sum += if (s1.get(v) === s2.get(v)) 1.0 else 0.0
      return sum
  }
  
  /**
   * joint: n-by-m matrix
   * pi: n - vector
   */
  def static checkMarginals(Matrix joint, Matrix pi) {
    if (joint.nRows !== pi.nRows || !pi.isVector)
      throw new RuntimeException
    val marginal = joint * ones(joint.nCols)
    for (i : 0 ..< joint.nRows)
      NumericalUtils::checkIsClose(marginal.get(i), pi.get(i))
  }
  
  def static cost(Matrix joint, Matrix costs) {
    var sum = 0.0
    for (i : 0 ..< joint.nRows)
      for (j : 0 ..< joint.nCols)
        sum += joint.get(i,j) * costs.get(i,j)
    return sum
  }
  
  def static checkPositiveSymmetric(Matrix matrix) {
    for (i : 0 ..< matrix.nRows)
      for (j : 0 ..< matrix.nCols) {
        NumericalUtils::checkIsClose(matrix.get(i,j), matrix.get(j,i))
        if (matrix.get(i,j) < 0.0)
          throw new RuntimeException
      }
  }
}