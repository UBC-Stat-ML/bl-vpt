package opt

import static  xlinear.MatrixOperations.*
import opt.schedules.Schedule
import blang.inits.Arg
import blang.inits.DefaultValue
import xlinear.DenseMatrix
import opt.schedules.Constant
import static extension opt.Utils.*


class Adam extends Optimizer {
  
  @Arg
    @DefaultValue("10e-8")
  double epsilon = 10e-8
  
  @Arg
  @DefaultValue("0.9")
  double beta1 = 0.9
  
  @Arg
  @DefaultValue("0.999")
  double beta2 = 0.999
  
  @Arg
  @DefaultValue("0.1")
  double stepScale = 0.1
  
  @Arg     @DefaultValue("Constant")
  Schedule schedule = new Constant
  
  DenseMatrix m = null
  DenseMatrix v = null
  
  override iterate(Objective obj, int t) {
    val stepSize = schedule.nextScaled(stepScale)
    val grad = obj.gradient
    ensureInit(grad.nEntries)
    
    val oldPoint = obj.currentPoint
    val newPoint = dense(grad.nEntries)
    for (d : 0 ..< newPoint.nEntries) {
      m.set(d, beta1 * m.get(d) + (1.0 - beta1) * grad.get(d))
      v.set(d, beta2 * v.get(d) + (1.0 - beta2) * grad.get(d) * grad.get(d))
      val mHat = m.get(d) / (1.0 - Math::pow(beta1, t+1))
      val vHat = v.get(d) / (1.0 - Math::pow(beta2, t+1))
      newPoint.set(d, oldPoint.get(d) - stepSize * mHat / (Math::sqrt(vHat) + epsilon))
    }
    
    obj.moveAvoidingNonFinite(newPoint)
  }
  
  def void ensureInit(int dim) {
    if (m === null) {
      m = dense(dim)
      v = dense(dim)
    }
  }
 
}