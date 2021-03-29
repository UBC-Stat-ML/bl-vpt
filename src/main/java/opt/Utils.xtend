package opt

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*
import bayonet.math.NumericalUtils

class Utils {
  
  def static double initialStepForNonZeroObjectives(Objective obj) {
    val currentHeight = obj.evaluate
    if (currentHeight < -NumericalUtils.THRESHOLD) throw new RuntimeException
    if (currentHeight <= 0.0) return 0.0;
    val gradient = obj.gradient
    return currentHeight / (gradient.norm ** 2)
  }
  
}