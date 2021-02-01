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

class TemperingObjective implements Objective {
    
  public VariationalPT vpt = null
  
  var double currentPoint
  var DenseMatrix currentGradient
  
  override moveTo(DenseMatrix updatedParameter) {
    vpt.parameters.setTo(updatedParameter)
    // reset statistics
    val pointGradientPair = estimate(null)
    currentPoint = pointGradientPair.key
    currentGradient = pointGradientPair.value
    
  }
  
  static class EstimationSettings {
    @Arg
    public double miniBurnInFraction = 0.5
  
    @Arg
    public int nScansPerGradient = 50
    
    @Arg
    public ObjectiveType objective
  }
  
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
        val expectedGradient = expectedGradient(p.samples.get(i), p.betas.get(i), p.betas.get(i)).estimate // E_i [ gradient_i ]
        val covar = crossTerm - probabilityOfTrunc * expectedGradient   // Covar[ gradient_i, T ]
        gradientTerms.add(covar)
      }
      val gradient = -2.0 * (gradientTerms.get(0) + gradientTerms.get(1))
      
      return reject -> gradient
    }
    
  }
    
  def Pair<Double,DenseMatrix> estimate(EstimationSettings settings) {
    
    // burn-in a bit?
    val nBurn = (settings.nScansPerGradient * settings.miniBurnInFraction) as int
    val it = vpt.pt
    for (i : 0 ..< nBurn) {
      moveKernel(nPassesPerScan)
      swapKernel
    }
    
    // samples list
    val samples = vpt.initSampleLists
    
    // record samples 
    val nSamples = settings.nScansPerGradient - nBurn
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
      val term = settings.objective.compute(pair)
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