package opt


import static extension xlinear.MatrixExtensions.*


class Careful_SGD extends Optimizer {
  
  var Double stepSize = null
    
  override iterate(Objective obj, int i) {
    if (stepSize === null)
      stepSize = Utils::initialStepForNonZeroObjectives(obj)
    val oldPt = obj.currentPoint.copy
    val oldObj = obj.evaluate
    obj.moveTo(obj.currentPoint - stepSize * obj.gradient)
    val newObj = obj.evaluate
    if (newObj > oldObj) {
      obj.moveTo(oldPt)
      stepSize = stepSize / 2.0
      println("\tstepsize=" + stepSize)
    }
  }
 
}