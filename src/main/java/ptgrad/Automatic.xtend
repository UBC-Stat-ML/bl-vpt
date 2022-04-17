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
import blang.core.ModelComponent
import java.util.Collection
import blang.core.LogScaleFactor
import blang.inits.DesignatedConstructor
import blang.inits.ConstructorArg
import java.util.Map
import blang.core.RealVar
import java.util.LinkedHashMap
import java.util.Set
import java.util.ArrayList
import blang.runtime.Runner
import blang.inits.parsing.Posix
import java.io.File
import blang.runtime.SampledModel
import blang.runtime.SampledModel.SampleWriter
import blang.runtime.internals.objectgraph.SkipDependency
import blang.runtime.internals.objectgraph.GraphAnalysis
import java.util.Collections
import blang.core.Model
import blang.runtime.internals.objectgraph.ObjectNode
import static extension ptbm.StaticUtils.*


import static extension ptgrad.Utils.logDensity;
import blang.core.ModelBuilder
import blang.runtime.Observations

class Automatic extends Interpolation 
{
  @SkipDependency(isMutable = true)
  val List<LogScaleFactor> target
  
  val Model m
 
  new(Map<String, RealVar> variables, Collection<String> parameterComponents, List<LogScaleFactor> target, Model m) {
    super(variables, parameterComponents)
    this.target = target
    this.m = m
  }
  
  def DerivativeStructure param(List<DerivativeStructure> it, String variable, VariationalParameterType t) { 
    get(t.paramName(variable))
  }
  
  override DerivativeStructure logDensity(List<DerivativeStructure> params) {
    val it = params.get(0)
    val beta = params.beta
    // compute fixed target
    var double targetLogDensity = target.logDensity
    
    if (!Double.isFinite(targetLogDensity))   
      return constant(Double.NEGATIVE_INFINITY)
    
    // compute variational target
    var variationalLogDensity = constant(0.0)
    for (variableName : variables.keySet) {
      val meanParam = param(params, variableName, VariationalParameterType::MEAN)
      val softPlusVarianceParam = param(params, variableName, VariationalParameterType::SOFTPLUS_VARIANCE)
      val sampled = variables.get(variableName).doubleValue
      variationalLogDensity += normalLogDensity(constant(sampled), meanParam, softPlusVarianceParam.softplus)
    }
    
    // interpolate (direct for now)
    val result = beta * targetLogDensity + (1.0 - beta) * variationalLogDensity
    
    return result
  }
  
  override sample(Random random, List<DerivativeStructure> it) {
    for (variableName : variables.keySet) {
      val meanParam = param(variableName, VariationalParameterType::MEAN).value
      val logVarianceParam = param(variableName, VariationalParameterType::SOFTPLUS_VARIANCE).value
      val varianceParam = logVarianceParam.softplus
      val sample = Generators::normal(random, meanParam, varianceParam)
      val WritableRealVar variable = variables.get(variableName) as WritableRealVar
      variable.set(sample)
    }
  }
  
  @DesignatedConstructor
  def static Automatic build(@ConstructorArg("target") ModelBuilder builder, @ConstructorArg("treatNaNAsNegativeInfinity") @DefaultValue("false") boolean treatNaNAsNegativeInfinity) {
    val m = builder.build
    val analysis = new GraphAnalysis(m, new Observations, treatNaNAsNegativeInfinity, true)
    val variables = variables(analysis)
    val target = analysis.factorsDefinedBy(m).filter(LogScaleFactor).toList
    return new Automatic(variables, Utils.parameterComponents(variables.keySet), target, m)
  }
  
  def static Map<String, RealVar> variables(GraphAnalysis analysis) {
    val named = new SampledModel(analysis).objectsToOutput
    val inverseNamed = new LinkedHashMap<Object, String>
    for (entry : named.entrySet)
      if (inverseNamed.containsKey(entry.value)) throw new RuntimeException
      else
        inverseNamed.put(entry.value, entry.key)
    
    var i = 0
    val result = new LinkedHashMap<String,RealVar>
    for (node : analysis.latentVariables) {
      if (node instanceof ObjectNode) {
        val variable = node.object
        if (variable instanceof RealVar) {
          val name = 
            if (inverseNamed.containsKey(variable)) 
              inverseNamed.get(variable)
            else
              "" + "id_" + i++
          result.put(name, variable)
        } else 
          System.err.println("WARNING: Type of variable not handled: " + variable.class)
      } else throw new RuntimeException
    }
    return result
  }
}