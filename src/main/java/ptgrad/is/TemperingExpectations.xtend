package ptgrad.is

import is.ImportanceSampler
import java.util.List
import is.StandardImportanceSampler
import is.DiagonalHalfSpaceImportanceSampler
import xlinear.DenseMatrix
import static extension java.lang.Math.*

import static xlinear.MatrixOperations.*

import static extension xlinear.MatrixExtensions.*

class TemperingExpectations {
  
  def static ImportanceSampler expectedGradient(List<Sample> samples, double scoreBeta) {
    return new StandardImportanceSampler(
      samples, 
      [gradient(scoreBeta)],
      [weight]
    ) 
  }
  
  def static ImportanceSampler expectedGradientTimesDelta(List<Sample> samples, double expectationBeta, List<Double> betas) {
    return new StandardImportanceSampler(
      samples, 
      [delta(betas) * gradient(expectationBeta)],
      [weight]
    ) 
  }
  
  def static ImportanceSampler expectedGradientDelta(List<Sample> samples, List<Double> betas) {
    return new StandardImportanceSampler(
      samples, 
      [gradientDelta(betas)],
      [weight] 
    ) 
  }
  
  def static ImportanceSampler expectedDelta(List<Sample> samples, List<Double> betas) {
    return new StandardImportanceSampler(
      samples, 
      [delta(betas).asMatrix],
      [weight]
    ) 
  }
  
  def static double delta(Sample s, List<Double> betas) {
    return s.logDensity(betas.get(1)) - s.logDensity(betas.get(0))
  }
  
  def static DenseMatrix gradientDelta(Sample s, List<Double> betas) {
    return s.gradient(betas.get(1)) - s.gradient(betas.get(0))
  }
  
  /**
   * Computes E[ 1[ acceptRatio <= 1 ] x acceptRatio ]
   * 
   * Uses: 
   * log(acceptRatio) 
   *             = logD_1(x_2) + logD_2(x_1) - logD_1(x_1) - logD_2(x_2)
   *             = {logD_2(x_1) - logD_1(x_1)} - {logD_2(x_2) - logD_1(x_2)}
   *             = delta(beta1, beta2, x_1) - delta(beta1, beta2, x_2)
   * 
   * Hence 1[ acceptRatio <= 1 ] = 1[ log(acceptRatio) <= 0 ]
   *                             = 1[ delta(beta1, beta2, x_1)  <= delta(beta1, beta2, x_2) ]
   *                             = 1[ -delta(beta1, beta2, x_1) >= -delta(beta1, beta2, x_2) ]
   * 
   * which is cast into DiagonalHalfSpaceImportanceSampler as 
   * 
   *                             = 1[ f1_i                        >= f2_j ]
   *                           
   * 
   * Next, 
   * 
   * acceptRatio = exp(delta(beta1, beta2, x_1)) exp( - delta(beta1, beta2, x_2) )
   * 
   * which is case into DiagonalHalfSpaceImportanceSampler as
   * 
   *             = G1_i                            G2_j
   */
  def static DiagonalHalfSpaceImportanceSampler<Sample,Sample> expectedUntruncatedRatio(ChainPair it) { 
    return new DiagonalHalfSpaceImportanceSampler(
      samples.get(0), [s | -delta(s, betas)], [s | exp( delta(s, betas)).asMatrix], [weight],
      samples.get(1), [s | -delta(s, betas)], [s | exp(-delta(s, betas)).asMatrix], [weight],
      false
    )
  }
  
  /**
   * 
   */
  def static DiagonalHalfSpaceImportanceSampler<Sample,Sample> expectedTruncatedGradient(ChainPair it, int chainIndex, DenseMatrix expectedGradient) {
    val one = ones(1)
    val first  = if (chainIndex === 0) [Sample s | s.gradient(betas.get(chainIndex)) - expectedGradient] else [one]
    val second = if (chainIndex === 0) [one] else [Sample s | (s.gradient(betas.get(chainIndex)) - expectedGradient).transpose] 
    return new DiagonalHalfSpaceImportanceSampler(
      samples.get(0), [s | delta(s, betas)], first, [weight], 
      samples.get(1), [s | delta(s, betas)], second, [weight],
      false
    )
  }
  
  // E[T grad W_0(X_1) i.e. as if chainIndex = 0
  def static DiagonalHalfSpaceImportanceSampler<Sample,Sample> expectedTruncatedCrossGradient(ChainPair it, DenseMatrix expectedGradient) {
    val one = ones(1)
    return new DiagonalHalfSpaceImportanceSampler(
      samples.get(0), [s | delta(s, betas)], [one], [weight], 
      samples.get(1), [s | delta(s, betas)], [Sample s | (s.gradient(betas.get(0)) - expectedGradient).transpose], [weight],
      false
    )
  }

  
  /**
   * Computes E[ 1[ acceptRatio > 1 ] ]
   * 
   * Similar strategy as expectedTruncatedRatio but with 
   * G1_i = G2_j = 1
   */
  def static DiagonalHalfSpaceImportanceSampler<Sample,Sample> probabilityOfTruncation(ChainPair it) {
    val one = ones(1)
    return new DiagonalHalfSpaceImportanceSampler(
      samples.get(0), [s | delta(s, betas)], [one], [weight],
      samples.get(1), [s | delta(s, betas)], [one], [weight],
      true
    )
  }

}