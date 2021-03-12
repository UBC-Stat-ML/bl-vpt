package ptgrad

import blang.core.WritableRealVar
import java.util.List
import org.apache.commons.math3.analysis.differentiation.DerivativeStructure
import java.util.Random
import blang.distributions.Generators

import static ptgrad.VariationalFactors.*

import static xlinear.MatrixOperations.*
import static extension java.lang.Math.*
import static extension xlinear.MatrixExtensions.*

import static extension xlinear.AutoDiff.*
import blang.types.StaticUtils
import blang.core.ModelBuilder
import blang.inits.Arg
import blang.inits.ConstructorArg
import java.util.Map
import blang.core.RealVar
import java.util.Collection
import blang.inits.DesignatedConstructor
import blang.runtime.internals.objectgraph.GraphAnalysis
import java.awt.image.SampleModel
import blang.runtime.SampledModel
import java.util.LinkedHashMap
import java.util.ArrayList

class Automatic 
  //extends Interpolation 
  {

//  
//  
////  def DerivativeStructure paramMu(List<DerivativeStructure> it) { get(_param_mu) }
////  def WritableRealVar x() { return variables.get(_variable_x) as WritableRealVar }
//  
//  override DerivativeStructure logDensity(List<DerivativeStructure> inputs) {
//    return null
////    val paramMu = inputs.paramMu
////    val beta = inputs.beta
////    val it = inputs.get(0)
////    val zero = constant(0.0)
////    val one = constant(1.0)
////    val half = constant(posteriorVariance)
////    val x = constant(x.doubleValue)
////    val y = constant(observation)
////    return 
////      beta * normalLogDensity(y, x, one) +                  // likelihood
////      (1.0 - beta) * normalLogDensity(x, paramMu, half) +   // variational distribution
////      beta * normalLogDensity(x, zero, one)                 // prior
//  }
//  
//  override sample(Random random, List<DerivativeStructure> it) {
//    throw new RuntimeException
////    val paramMu = paramMu
////    x.set(Generators::normal(random, paramMu.value, posteriorVariance))
//  }
//  
//  new (Map<String,RealVar> variables, Collection<String> parameterComponents) { 
//    super(variables, parameterComponents)
//  }
//  
//  def static mean(String param) { return param + "_mean" }
//  def static variance(String param) { return param + "_variance" }
//  
//  @DesignatedConstructor
//  def static Automatic build(@ConstructorArg("model") ModelBuilder model) {
//    val analysis = new GraphAnalysis(model.build)
//    val sampled = new SampledModel(analysis)
//    val variables = new LinkedHashMap<String,RealVar>
//    val parameterComponents = new ArrayList<String>
//    var int i = 0
//    for (node : analysis.latentVariables) {
//      val variable = GraphAnalysis::getLatentObject(node)
//      if (variable instanceof WritableRealVar) {
//        variables.put()
//      } else throw new RuntimeException
//      i++
//    }
//    null
//  }
}