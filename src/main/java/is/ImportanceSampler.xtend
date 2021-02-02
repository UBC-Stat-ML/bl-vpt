package is

import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*

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
    val estimate = estimate

    // See Owen, IS chapter, p.9, https://statweb.stanford.edu/~owen/mc/Ch-var-is.pdf
    val varianceEstimate = (weightedSum(2, 2) - 2.0 * estimate * weightedSum(2, 1) + estimate * estimate * sumSqWeights) / Math::pow(sumWeights, 2)
    val result = dense(varianceEstimate.nEntries)
    for (i : 0 ..< result.nEntries)
      result.set(i, Math::sqrt(varianceEstimate.get(i)))
    return result
  }
  
  def double ess() {
    return Math::pow(sumWeights, 2) / sumSqWeights
  }
}