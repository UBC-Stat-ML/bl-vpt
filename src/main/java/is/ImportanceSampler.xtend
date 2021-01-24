package is

import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*

abstract class ImportanceSampler {
  def DenseMatrix weightedSum(int weightPower, int functionPower)
  
  private def double sumWeights() { 
    return weightedSum(1, 0).get(0)
  }

  private def double sumSqWeights()  {
    return weightedSum(2, 0).get(0)
  }
  
  def DenseMatrix estimate() {
    return weightedSum(1, 1) / sumWeights
  }
  
  def DenseMatrix standardError() {
    val estimate = estimate
    val varianceEstimate = weightedSum(2, 2) - 2 * estimate * weightedSum(2, 1) + estimate * sumSqWeights
    val result = dense(varianceEstimate.nEntries)
    for (i : 0 ..< result.nEntries)
      result.set(i, Math::sqrt(varianceEstimate.get(i)))
    return result
  }
  
  def double ess() {
    return Math::pow(sumWeights, 2) / sumSqWeights
  }
}