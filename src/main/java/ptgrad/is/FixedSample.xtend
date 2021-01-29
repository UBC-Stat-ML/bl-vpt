package ptgrad.is

import xlinear.DenseMatrix
import java.util.Map
import java.util.HashMap
import ptgrad.Interpolation

class FixedSample implements Sample {
  
  val Map<Double, Double> logDensities
  val Map<Double, DenseMatrix> gradients
  
  new (Interpolation p, Iterable<Double> betas) {
    logDensities = new HashMap
    gradients = new HashMap
    for (beta : betas) {
      logDensities.put(beta, p.logDensity(beta))
      gradients.put(beta, p.gradient(beta))
    }
  }
  
  override weight() { 1.0 }
  
  override logDensity(double beta) {
    return logDensities.get(beta)
  }
  
  override gradient(double beta) {
    return gradients.get(beta)
  }
  
}