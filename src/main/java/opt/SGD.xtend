package opt


import static extension xlinear.MatrixExtensions.*
import opt.schedules.Schedule
import blang.inits.Arg
import blang.inits.DefaultValue
import opt.schedules.Polynomial

class SGD extends Optimizer {
  
  @Arg     @DefaultValue("Polynomial")
  Schedule schedule = new Polynomial
  
  @Arg       @DefaultValue("true")
  boolean simpleBacktrack = true
  
  var Double stepScale = null
    
  override iterate(Objective obj, int i) {
    if (stepScale === null)
      stepScale = Utils::initialStepForNonZeroObjectives(obj)
    val oldPt = obj.currentPoint.copy
    val oldObj = obj.evaluate
    
    val grad = obj.gradient
    val stepSize = schedule.nextScaled(stepScale)
    obj.moveTo(obj.currentPoint - stepSize * grad)
    val newObj = obj.evaluate
    if (simpleBacktrack && !(newObj < oldObj)) {
      obj.moveTo(oldPt)
      println('\t' + "backtracked since !" + newObj + " < " + oldObj)
    }
  }
 
}