package ptgrad.is

import xlinear.DenseMatrix
import java.util.Map
import java.util.HashMap
import ptgrad.Interpolation

class FixedSample implements Sample {
  
  val Map<Double, Double> logDensities
  val Map<Double, DenseMatrix> gradients
  val double referenceBeta
  val double weight
  
  new (Interpolation p, Iterable<Double> betas, double referenceBeta) {
    logDensities = new HashMap
    gradients = new HashMap
    this.referenceBeta = referenceBeta
    this.weight = 1.0
    for (beta : betas) {
      logDensities.put(beta, p.logDensity(beta))
      gradients.put(beta, p.gradient(beta))
    }
  }
  
  new (Map<Double, Double> logDensities, Map<Double, DenseMatrix> gradients, double referenceBeta, double weight) {
    this.logDensities = logDensities
    this.gradients = gradients
    this.referenceBeta = referenceBeta
    this.weight = weight
  }
  
  override weight() { weight }
  
  override logDensity(double beta) {
    return logDensities.get(beta)
  }
  
  override gradient(double beta) {
    return gradients.get(beta)
  }
  
  override importanceSample(double betaPrime) {
    if (betaPrime === referenceBeta) throw new RuntimeException
    if (weight !== 1.0) 
      throw new RuntimeException
    // w \propto target / proposal
    val weight = Math::exp( logDensity(betaPrime) - logDensity(referenceBeta))
    return new FixedSample(this.logDensities, this.gradients, betaPrime, weight) 
  }
  
}