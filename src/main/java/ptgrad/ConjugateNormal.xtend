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

class ConjugateNormal extends Interpolation {
  
  val static String _param_mu = "param_mu"
  val static String _variable_x = "x"
  
  val observation = 3.0
  val posteriorVariance = 0.5
  
  def DerivativeStructure paramMu(List<DerivativeStructure> it) { get(_param_mu) }
  def WritableRealVar x() { return variables.get(_variable_x) as WritableRealVar }
  
  override DerivativeStructure logDensity(List<DerivativeStructure> inputs) {
    val paramMu = inputs.paramMu
    val beta = inputs.beta
    val it = inputs.get(0)
    val zero = constant(0.0)
    val one = constant(1.0)
    val half = constant(posteriorVariance)
    val x = constant(x.doubleValue)
    val y = constant(observation)
    return 
      beta * normalLogDensity(y, x, one) +                  // likelihood
      (1.0 - beta) * normalLogDensity(x, paramMu, half) +   // variational distribution
      beta * normalLogDensity(x, zero, one)                 // prior
  }
  
  override sample(Random random, List<DerivativeStructure> it) {
    val paramMu = paramMu
    x.set(Generators::normal(random, paramMu.value, posteriorVariance))
  }
  
  new() {
    super(#{_variable_x -> StaticUtils::latentReal}, #{_param_mu})
  }
}