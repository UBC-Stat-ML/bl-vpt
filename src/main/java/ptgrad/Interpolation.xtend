package ptgrad

import java.util.Map
import blang.core.RealVar
import java.util.Random
import org.apache.commons.math3.analysis.differentiation.DerivativeStructure
import java.util.List
import xlinear.AutoDiff.Differentiable
import briefj.Indexer
import java.util.Collection
import blang.types.AnnealingParameter
import xlinear.DenseMatrix
import xlinear.MatrixOperations
import java.util.ArrayList
import blang.inits.Implementations
import blang.runtime.internals.objectgraph.SkipDependency
import xlinear.AutoDiff

/**
 * One point in a sequence of distributions from a tractable one to 
 * an intractable one.
 */
@Implementations(ConjugateNormal, ToyNormal, CHRVariational)
abstract class Interpolation  {
  // variables need to be populated right away at construction time
  new (Map<String,RealVar> variables, Collection<String> parameterComponents) { 
    this.variables = variables
    this.parameterComponents = new Indexer<String>(parameterComponents)
    parameters = MatrixOperations::dense(parameterComponents.size)
    p = parameters.nEntries
  }
  
  // ("variational") parameters
  @SkipDependency(isMutable = false)
  val Indexer<String> parameterComponents
  
  @SkipDependency(isMutable = false)
  public var DenseMatrix parameters
  val int p
  def void setParameters(DenseMatrix parameters) { this.parameters = parameters }
  
  // APIs to subclass
  // Convention: last item in list will be beta
  def DerivativeStructure logDensity(List<DerivativeStructure> it)
  def void sample(Random random, List<DerivativeStructure> it)

  // APIs used by the PT sampler
  public val Map<String,RealVar> variables
  def double logDensity(double beta) {
    return logDensity(variationalInputs(0, beta)).value
  }
  def DenseMatrix gradient(double beta) {
    val derivStruct = logDensity(variationalInputs(1, beta))
    return AutoDiff::gradient(derivStruct)
  }
  def double logDensity(AnnealingParameter beta) {
    logDensity(beta.doubleValue)
  }
  def void sample(Random random) {
    sample(random, variationalInputs(0, 0.0))
  }
  
  // utilities
  def DerivativeStructure get(List<DerivativeStructure> it, String component) {
    it.get(parameterComponents.o2i(component))
  }
  def DerivativeStructure beta(List<DerivativeStructure> it) {
    it.get(it.size - 1)
  }
  def List<DerivativeStructure> variationalInputs(int order, double beta) {
    variationalInputs(order, constant(order, beta))
  }
  def List<DerivativeStructure> variationalInputs(int order, DerivativeStructure beta) {
    val List<DerivativeStructure> inputs = new ArrayList(p + 1)
    for (i : 0 ..< p) 
      inputs.add(new DerivativeStructure(parameters.nEntries, order, i, parameters.get(i)))
    inputs.add(beta)
    return inputs
  }

  def DerivativeStructure constant(int order, double value) {
    new DerivativeStructure(parameters.nEntries, order, value)
  }
  def DerivativeStructure constant(DerivativeStructure template, double value) {
    constant(template.order, value)
  }
}