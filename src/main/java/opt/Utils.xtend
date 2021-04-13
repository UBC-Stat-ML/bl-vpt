package opt

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*
import bayonet.math.NumericalUtils
import xlinear.DenseMatrix

class Utils {
  
  def static double initialStepForNonZeroObjectives(Objective obj) {
    val currentHeight = obj.evaluate
    if (currentHeight < -NumericalUtils.THRESHOLD) throw new RuntimeException
    if (currentHeight <= 0.0) return 0.0;
    val gradient = obj.gradient
    return currentHeight / (gradient.norm ** 2)
  }
  
  def static void moveAvoidingNonFinite(Objective obj, DenseMatrix updatedParams) {
    val oldPt = obj.currentPoint.copy
    var newObj = Double.NaN
    try {
      obj.moveTo(updatedParams)
      newObj = obj.evaluate
    } catch (RuntimeException e) { // TODO: clean up
      if (!e.message.contains("Factors should not return NaN"))
        throw e
    }
    if (!Double.isFinite(newObj)) {
      obj.moveTo(oldPt)
      println('\t' + "backtracked since newObj = " + newObj)
    }
  }
  
}