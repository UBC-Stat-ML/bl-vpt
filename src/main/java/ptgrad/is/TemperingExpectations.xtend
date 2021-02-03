package ptgrad.is

import is.ImportanceSampler
import java.util.List
import is.StandardImportanceSampler
import is.DiagonalHalfSpaceImportanceSampler
import xlinear.DenseMatrix
import xlinear.MatrixOperations
import static extension java.lang.Math.*

import static xlinear.MatrixOperations.*

import static extension xlinear.MatrixExtensions.*
import blang.runtime.Runner
import blang.inits.experiments.tabwriters.TabularWriter
import org.eclipse.xtend.lib.annotations.Data

class TemperingExpectations {
  
  def static ImportanceSampler expectedGradient(List<Sample> samples, double scoreBeta) {
    return new StandardImportanceSampler(
      samples, 
      [gradient(scoreBeta)],
      [weight] // fixed weight here!
    ) 
  }
  
  def static ImportanceSampler expectedGradientTimesDelta(List<Sample> samples, double expectationBeta, List<Double> betas) {
    return new StandardImportanceSampler(
      samples, 
      [(gradient(betas.get(1)) - gradient(betas.get(0))) * logDensity(expectationBeta)],
      [weight] // fixed weight here!
    ) 
  }
  
  def static double delta(Sample s, List<Double> betas) {
    return s.logDensity(betas.get(1)) - s.logDensity(betas.get(0))
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
      samples.get(0), [s | -delta(s, betas)], [s | exp( delta(s, betas)).toMtx], [weight],
      samples.get(1), [s | -delta(s, betas)], [s | exp(-delta(s, betas)).toMtx], [weight],
      false
    )
  }
  
  /**
   * 
   */
  def static DiagonalHalfSpaceImportanceSampler<Sample,Sample> expectedTruncatedGradient(ChainPair it, int chainIndex) {
    val one = ones(1)
    val first  = if (chainIndex === 0) [Sample s | s.gradient(betas.get(chainIndex))] else [one]
    val second = if (chainIndex === 0) [one] else [Sample s | s.gradient(betas.get(chainIndex))]
    return new DiagonalHalfSpaceImportanceSampler(
      samples.get(0), [s | delta(s, betas)], first, [weight], // fixed a sign here!
      samples.get(1), [s | delta(s, betas)], second, [weight],
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
  
  /**
   * Note:
   * 
   * acceptanceProbability = min(1, acceptRatio)
   *                       = 1[ acceptRatio <= 1 ] acceptRatio + 1[ acceptRatio > 1 ] 1.0
   */
  
  def static DenseMatrix toMtx(double x) {
    val item = newDoubleArrayOfSize(1)
    item.set(0, x)
    return MatrixOperations::denseCopy(item)
  }
}