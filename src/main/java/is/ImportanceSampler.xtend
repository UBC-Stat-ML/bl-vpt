package is

import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*

import static extension java.lang.Math.*

abstract class ImportanceSampler {
  def DenseMatrix weightedSum(int weightPower, int functionPower)
  
  def double sumWeights() { 
    return weightedSum(1, 0).get(0)
  }

  private def double sumSqWeights()  {
    return weightedSum(2, 0).get(0)
  }
  
  def DenseMatrix estimate(int functionPower) {
    return weightedSum(1, functionPower) / sumWeights
  }
  
  def DenseMatrix estimate() { estimate(1) }
  
  def DenseMatrix standardError() {
    val estimate = estimate()
    val w22 = weightedSum(2, 2)
    val w21 = weightedSum(2, 1)
    val sumSqWeights = sumSqWeights()
    val sumW2 = sumWeights.pow(2)
    // See Owen, IS chapter, p.9, https://statweb.stanford.edu/~owen/mc/Ch-var-is.pdf
    estimate.editInPlace[r, c, est|sqrt((w22.get(r,c) - 2.0 * est * w21.get(r,c) + est.pow(2) * sumSqWeights) / sumW2)]
    return estimate
  }
  
  def double ess() {
    return pow(sumWeights, 2) / sumSqWeights
  }
}