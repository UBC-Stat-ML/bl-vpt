package opt

import static xlinear.MatrixOperations.*

import static extension xlinear.MatrixExtensions.*

class SGD extends Optimizer {
  
  new(Objective obj) {
    super(obj)
  }
  
  override iterate(int i) {
    return obj.currentPoint - rate(i) * obj.gradient
  }
  
  def double rate(int i) {
    return 0.1 // TODO: decrease
  }
  
  def static void main(String [] args) {
    val toyObjective = TestObjectives::quadratic
    val sgd = new SGD(toyObjective) => [maxIters = 50]
    sgd.optimize
    println(sgd.obj.currentPoint)
  }
  
}