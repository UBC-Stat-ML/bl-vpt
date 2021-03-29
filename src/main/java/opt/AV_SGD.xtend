package opt


import static extension xlinear.MatrixExtensions.*

/**
 * An SGD for absolute value like functions. 
 */
class AV_SGD extends Optimizer {
    
  override iterate(Objective obj, int i) {
    val currentStepSize = Utils::initialStepForNonZeroObjectives(obj)
    obj.moveTo(obj.currentPoint - currentStepSize * obj.gradient)
  }
 
}