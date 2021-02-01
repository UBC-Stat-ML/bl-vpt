package ptgrad

import opt.Objective
import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Data
import blang.types.StaticUtils
import static extension blang.types.ExtensionUtils.*
import blang.inits.Arg
import xlinear.MatrixOperations
import java.util.List
import ptgrad.is.Sample
import ptgrad.is.ChainPair
import blang.inits.experiments.tabwriters.TabularWriter

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
  }
  
  static interface Variant {
    def Pair<Double,DenseMatrix> compute(ChainPair p, TabularWriter logs)
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
    val objectiveSum = 0.0
    val gradientSum = MatrixOperations::dense(vpt.parameters.nEntries)
    val betas = vpt.betas()
    for (int c : 0 ..< (nChains - 1)) {
      val beta1 = betas.get(c)
      val beta2 = betas.get(c + 1)
      val pair = new ChainPair(beta1, beta2, samples.get(beta1), samples.get(beta2))
      
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