package ptgrad.is

import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import xlinear.DenseMatrix
import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*
import org.eclipse.xtend.lib.annotations.Data

@Data
class ImportanceSamplingEstimate {
  val DenseMatrix sumWeightedSamples 
  val double sumWeights
  val double sumSqWeights
  
  def DenseMatrix value() {
    return sumWeightedSamples / sumWeights
  } 
  
  def double ess() {
    return Math::pow(sumWeights, 2) / sumSqWeights
  }
  

}