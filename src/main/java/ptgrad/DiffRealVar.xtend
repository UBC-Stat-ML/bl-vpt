package ptgrad

import static extension java.lang.Math.*
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.eclipse.xtend.lib.annotations.Data
import java.util.List

class DiffRealVar {
  
//  val double value
//  val Procedure1<DiffRealVar> backprop
//  var double differential = 0.0
// 
//  val List<DiffRealVar> inputs
//  var nOutgoingEdges = 0
//  var nRecurseCalls = 0
//  
//  private new(List<DiffRealVar> inputs, double value, Procedure1<DiffRealVar> backprop) { 
//    this.inputs = inputs
//    this.value = value
//    this.backprop = backprop
//    for (input : inputs)
//      input.nOutgoingEdges++
//  }
//    
//  def static DiffRealVar defineBackProp(double value, Procedure1<DiffRealVar> backprop) {
//    new DiffRealVar(value, backprop)
//  }
//  
//  def static DiffRealVar variable(double value) {
//    new DiffRealVar(value) []
//  }
//  
//  def computeGradient() {
//    this.differential = 1.0
//    backprop.apply(this) 
//  }
//    
//  def static DiffRealVar sin(DiffRealVar x) {
//    x.nOutgoingEdges++
//    sin(x.value).defineBackProp [
//      x.differential += it.differential * cos(x.value)
//      x.recurse
//    ]    
//  }
//  
//  def static DiffRealVar *(DiffRealVar x0, DiffRealVar x1) {
//    
//    x0.nOutgoingEdges++
//    x1.nOutgoingEdges++
//    (x0.value * x1.value).defineBackProp[
//      x0.differential += it.differential * x1.value
//      x1.differential += it.differential * x0.value
//      x0.recurse
//      x1.recurse
//    ]
//  }
//  
//  def DiffRealVar defineDerivative(double value, DiffRealVar x0, Procedure1<DiffRealVar> backProp) {
//    
//  }
//  
//  def void recurse() { 
//    nRecurseCalls++
//    if (nRecurseCalls === nOutgoingEdges) {
//      backprop.apply(this)
//      for (input : inputs)
//        input.recurse()
//    }
//  }
//  
//  def static void main(String [] args) {
//    val x0 = variable(1.0)
//    val x1 = variable(2.0)
//    val prod = x0 * x1 * x0 * x0
//    val result = sin(prod) * x0
//    result.computeGradient
//    println(x0.differential)
//    println(x1.differential)
//  }
  
}