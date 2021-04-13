package opt


import static extension xlinear.MatrixExtensions.*
import opt.schedules.Schedule
import blang.inits.Arg
import blang.inits.DefaultValue
import opt.schedules.Polynomial

import static extension opt.Utils.*

class SGD extends Optimizer {
  
  @Arg     @DefaultValue("Polynomial")
  Schedule schedule = new Polynomial

  @Arg
  @DefaultValue("0.1")
  double stepScale = 0.1
    
  override iterate(Objective obj, int i) {
    val grad = obj.gradient
    val stepSize = schedule.nextScaled(stepScale)
    obj.moveAvoidingNonFinite(obj.currentPoint - stepSize * grad)
  }
 
}