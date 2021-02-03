package ptgrad

import opt.Objective
import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Data
import blang.types.StaticUtils
import static extension blang.types.ExtensionUtils.*
import blang.inits.Arg
import xlinear.MatrixOperations
import static extension xlinear.MatrixExtensions.*
import java.util.List
import ptgrad.is.Sample
import ptgrad.is.ChainPair
import blang.inits.experiments.tabwriters.TabularWriter
import static ptgrad.is.TemperingExpectations.*
import java.util.ArrayList
import blang.inits.Implementations
import blang.inits.DefaultValue
import bayonet.math.NumericalUtils

class TemperingObjective implements Objective {
  val VariationalPT vpt 
  
  new(VariationalPT vpt) { 
    this.vpt = vpt
    moveTo(vpt.parameters.copy) // force initial recompute
  }
  
  var double currentPoint
  var DenseMatrix currentGradient
  
  override moveTo(DenseMatrix updatedParameter) {
    vpt.parameters.setTo(updatedParameter)
    // reset statistics
    val pointGradientPair = estimate()
    currentPoint = pointGradientPair.key
    currentGradient = pointGradientPair.value
  }
  
  @Implementations(Rejection, SKL, SqrtHalfSKL, Inef)
  static interface ObjectiveType {
    def Pair<Double,DenseMatrix> compute(ChainPair p)
  }
  
  static class Rejection implements ObjectiveType {
    
    override compute(ChainPair p) {
      
      // in the following, let T = 1[ acceptRatio > 1 ]
      
      // point
      val expectedUntruncatedRatio = expectedUntruncatedRatio(p).estimate.get(0) // E[ (1 - T) x acceptRatio ]
      val probabilityOfTrunc = probabilityOfTruncation(p).estimate.get(0)        // E[ T ]
      val accept = expectedUntruncatedRatio + probabilityOfTrunc
      val reject = 1.0 - accept
      
      // gradient
      val gradientTerms = new ArrayList<DenseMatrix>(2)
      for (i : 0 ..< 2) {
        val crossTerm = expectedTruncatedGradient(p, i).estimate                                           // E [ gradient_i x T ]
        val expectedGradient = expectedGradient(p.samples.get(i), p.betas.get(i)).estimate // E_i [ gradient_i ]
        val covar = crossTerm - probabilityOfTrunc * expectedGradient   // Covar[ gradient_i, T ]
        gradientTerms.add(covar)
      }
      val gradient = -2.0 * (gradientTerms.get(0) + gradientTerms.get(1))
      
      return reject -> gradient
    }
    
  }
  
  static class Inef implements ObjectiveType {
    val Rejection rej = new Rejection
    
    override compute(ChainPair p) {
      val rejObj = rej.compute(p)
      val r = rejObj.key
      val s = 1.0 - r
      return (r/s) -> (rejObj.value / Math::pow(s, 2))
    }
    
  }
  
  static class SqrtHalfSKL implements ObjectiveType {
    val SKL skl = new SKL
    override compute(ChainPair p) {
      val sklObj = skl.compute(p)
      val obj = if (sklObj.key <= 0.0) 1e-6 else Math::sqrt(0.5 * sklObj.key)
      return obj -> (sklObj.value / 4.0 / obj)
    }
  }
  
  static class SKL implements ObjectiveType {
    
    override compute(ChainPair p) {
      val objectiveTerms = new ArrayList<Double>(2)
      val gradientTerms = new ArrayList<DenseMatrix>(2)
      
      for (i : 0 ..< 2) {
        val samples = p.samples.get(i)
        val beta = p.betas.get(i)
        val expectedDelta = expectedDelta(samples, p.betas).estimate
        objectiveTerms.add(expectedDelta.doubleValue)
        
        gradientTerms +=
          expectedGradientTimesDelta(samples, beta, p.betas).estimate -
          expectedGradient(samples, beta).estimate * expectedDelta +
          expectedGradientDelta(samples, p.betas).estimate
          
      }
      
      return (objectiveTerms.get(1) - objectiveTerms.get(0)) -> (gradientTerms.get(1) - gradientTerms.get(0))
    }
    
  }
    
  def Pair<Double,DenseMatrix> estimate() {
    
    // burn-in a bit?
    val nBurn = (vpt.nScansPerGradient * vpt.miniBurnInFraction) as int
    val it = vpt.pt
    for (i : 0 ..< nBurn) {
      moveKernel(nPassesPerScan)
      swapKernel
    }
    
    // samples list
    val samples = vpt.initSampleLists
    
    // record samples 
    val nSamples = vpt.nScansPerGradient - nBurn
    for (i : 0 ..< nSamples) {
      moveKernel(nPassesPerScan)
      swapKernel
      vpt.record(samples)
    }
    
    // compute importance sampling estimators
    var objectiveSum = 0.0
    var gradientSum = MatrixOperations::dense(vpt.parameters.nEntries)
    val betas = vpt.betas()
    for (int c : 0 ..< (nChains - 1)) {
      val beta0 = betas.get(c)
      val beta1 = betas.get(c + 1)
      val pair = new ChainPair(#[beta0, beta1], #[samples.get(beta0), samples.get(beta1)])
      val term = vpt.objective.compute(pair)
      objectiveSum += term.key
      gradientSum += term.value
    }
    
    return objectiveSum -> gradientSum
  }
  
  override currentPoint() {
    vpt.parameters 
  }
  
  override evaluate() {
    currentPoint
  }
  
  override gradient() {
    currentGradient
  }
  
}