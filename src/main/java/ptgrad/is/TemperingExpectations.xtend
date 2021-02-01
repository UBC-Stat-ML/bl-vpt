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
  
  def static ImportanceSampler expectedGradient(List<Sample> samples, double expectationBeta, double scoreBeta) {
    return new StandardImportanceSampler(
      samples, 
      [gradient(scoreBeta)],
      [logDensity(expectationBeta)]
    ) 
  }
  
  def static double delta(Sample s, double beta1, double beta2) {
    return s.logDensity(beta2) - s.logDensity(beta1)
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
   * acceptRatio = exp(delta(beta2, beta1, x_1)) exp( - delta(beta2, beta1, x_2) )
   * 
   * which is case into DiagonalHalfSpaceImportanceSampler as
   * 
   *             = G1_i                            G2_j
   */
  def static DiagonalHalfSpaceImportanceSampler<Sample,Sample> expectedUntruncatedRatio(ChainPair it) { 
    return new DiagonalHalfSpaceImportanceSampler(
      samples1, [s | -delta(s, beta1, beta2)], [s | exp( delta(s, beta1, beta2)).toMtx], [weight],
      samples2, [s | -delta(s, beta1, beta2)], [s | exp(-delta(s, beta1, beta2)).toMtx], [weight],
      false
    )
  }
  
  def static DiagonalHalfSpaceImportanceSampler<Sample,Sample> _expectedTruncatedGradient(ChainPair it) {
    val one = ones(1)
    return new DiagonalHalfSpaceImportanceSampler(
      samples1, [s | -delta(s, beta1, beta2)], [s | s.gradient(beta1)], [weight],
      samples2, [s | -delta(s, beta1, beta2)], [one], [weight],
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
      samples1, [s | delta(s, beta1, beta2)], [one], [weight],
      samples2, [s | delta(s, beta1, beta2)], [one], [weight],
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