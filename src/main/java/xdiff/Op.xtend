package xdiff

import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import blang.core.RealVar
import org.nd4j.linalg.api.ndarray.INDArray

@Data
abstract class Op {
  
//  protected val List<RealVar> inputs
//  /**
//   * Derivative of the output of this Op w.r.t. the inputIndex 
//   */
//  def double derivative(int inputIndex)
//  def double compute()
//  
//  /// find better ways for that?
//  /// e.g. Op1, Op2, etc?
//  
//  def static RealVar x0(Op op) { op.inputs.get(0) }
//  def static RealVar x1(Op op) { op.inputs.get(1) }
//  
//  // e.gs of Ops
//  
//  static class Product extends Op {
//    new(RealVar input0, RealVar input1) { super(#[input0, input1]) }
//    
//    override compute() { x0.doubleValue * x1.doubleValue }
//    
//    override double derivative(int inputIndex) {
//      val other = inputs.get(1 - inputIndex)
//      return other.doubleValue
//    }
//  }
//  
//
//  
//  static class Sin extends Op {
//    new(RealVar input0) { super(#[input0]) }
//    
//    override compute() { Math::sin(x0.doubleValue) }
//    
//    override double derivative(int inputIndex) {
//      return Math::cos(x0.doubleValue)
//    }
//  }
//  
//  
//  def static DiffRealVar *(RealVar x0, RealVar x1) {
//    return new DiffRealVar(new Product(x0, x1))
//  }
//  
//  def static DiffRealVar sin(RealVar x0) {
//    return new DiffRealVar(new Sin(x0))
//  }
//  
//  // prototype impl of diff real var
//  // might be cleaner to just do a toposort (?)
//  // or start with the g-d tape
//  
//  def static void backpropagate(List<DiffRealVar> order) {
//    order.last.differential = 1.0
//    for (it : order.reverseView) {
//      for (inputIndex : 0 ..< op.inputs.size) {
//        val input = op.inputs.get(inputIndex)
//        if (input instanceof DiffRealVar) {
//          val derivative = op.derivative(inputIndex)
//          input.differential += differential * derivative
//        }
//      }
//    }
//  }
//  
//  static class DiffRealVar implements RealVar {
//    val double value
//    val Op op
//    var double differential = 0.0
//    
//    new(Op op) {
//      this.value = op.compute
//      this.op = op
//    }
//
//    override doubleValue() { value }
//  }
//  
//  def static void main(String[] args) {
//    val INDArray test = null
//  }

///
  
//  static class DiffRealVar implements RealVar {
//    val double value
//    val Op op
//    var nOutgoingEdges = 0
//    var double differential = 0.0
//    var nRecurseCalls = 0
//    
//    new(Op op) {
//      this.value = op.compute
//      this.op = op
//      for (input : op.inputs.filter(DiffRealVar))
//        input.nOutgoingEdges++
//    }
//    
//    
//    
//    private def void backPropagate() {
//      for (inputIndex : 0 ..< op.inputs.size) {
//        val input = op.inputs.get(inputIndex)
//        if (input instanceof DiffRealVar) {
//          val derivative = op.derivative(inputIndex)
//          input.differential += this.differential * derivative
//          input.nRecurseCalls++
//          
//        }
//      }
//    }
//    
//    override doubleValue() { value }
//  }
  
}