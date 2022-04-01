package ptgrad.tests

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
import static extension ptgrad.Utils.logDensity;
import ptgrad.Interpolation
import ptgrad.VariationalParameterType
import ptgrad.Utils

class CHRVariational extends Interpolation {
  
  @SkipDependency(isMutable = true)
  val List<LogScaleFactor> target
  
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
      variationalLogDensity += logNormalLogDensity(constant(sampled), meanParam, (softPlusVarianceParam.exp).log1p)
    }
    
    // interpolate (direct for now)
    val result = beta * targetLogDensity + (1.0 - beta) * variationalLogDensity
    
    return result
  }
  
  override sample(Random random, List<DerivativeStructure> it) {
    for (variableName : variables.keySet) {
      val stdNormalSample = random.nextGaussian
      
      val meanParam = param(variableName, VariationalParameterType::MEAN).value
      val logVarianceParam = param(variableName, VariationalParameterType::SOFTPLUS_VARIANCE).value
      val varianceParam = Math::log1p(Math::exp(logVarianceParam))
      val sample = Math::exp(meanParam + Math::sqrt(varianceParam) * stdNormalSample)
      
      val WritableRealVar variable = variables.get(variableName) as WritableRealVar
      
      variable.set(sample)
    }
  }
  
  new (Map<String,RealVar> variables, Collection<String> parameterComponents, List<LogScaleFactor> target) { 
    super(variables, parameterComponents)
    this.target = target
  }
  
  @DesignatedConstructor
  def static CHRVariational build() {
    val model = loadModel()
    val variables = variables(model)
    val analysis = new GraphAnalysis(model)
    val target = analysis.factorsDefinedBy(model).filter(LogScaleFactor).toList
    return new CHRVariational(variables, Utils.parameterComponents(variables.keySet), target)
  }
  
  
  
  def static CollapsedHierarchicalRockets loadModel() {
    val runner = Runner::create(new File(""),
      "--model", "ptgrad.CollapsedHierarchicalRockets", 
      "--model.data", "data/failure_counts.csv")
    return runner.model as CollapsedHierarchicalRockets
  }
  
  def static Map<String,RealVar> variables(CollapsedHierarchicalRockets target) {
    val result = new LinkedHashMap
    result.put("a", target.a)
    result.put("b", target.b)
    return result
  }
}