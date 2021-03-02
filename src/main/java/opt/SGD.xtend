package opt

import static xlinear.MatrixOperations.*

import static extension xlinear.MatrixExtensions.*

class SGD extends Optimizer {
  
  override iterate(Objective obj, int i) {
    return obj.currentPoint - rate(i) * obj.gradient
  }
  
  def double rate(int i) {
    return 0.1 // TODO: decrease
  }
  
}