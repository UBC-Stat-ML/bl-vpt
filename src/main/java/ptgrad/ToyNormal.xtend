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
import blang.inits.Arg
import blang.inits.DefaultValue

class ToyNormal extends Interpolation {
  
  val static String _param_delta = "param_delta"
  val static String _variable_x = "x"
  
  @Arg @DefaultValue("0.0")
  public double mu0 = 0.0
  
  def DerivativeStructure paramDelta(List<DerivativeStructure> it) { get(_param_delta) }
  def WritableRealVar x() { return variables.get(_variable_x) as WritableRealVar }
  
  override DerivativeStructure logDensity(List<DerivativeStructure> inputs) {
    val paramDelta = inputs.paramDelta
    val beta = inputs.beta
    val it = inputs.get(0)
    val one = constant(1.0)
    val x = constant(x.doubleValue)
    val mean = paramDelta * beta + (1.0 - beta) * mu0
    return normalLogDensity(x, mean, one)
  }
  
  override sample(Random random, List<DerivativeStructure> it) {
    x.set(Generators::normal(random, 0.0, 1.0))
  }
  
  new() {
    super(#{_variable_x -> StaticUtils::latentReal}, #{_param_delta})
  }
}