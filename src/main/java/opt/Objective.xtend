package opt

import xlinear.DenseMatrix
import java.util.Map
import java.util.Optional

/**
 * By default, minimization is considered
 */
interface Objective {
  def void moveTo(DenseMatrix updatedParameter)
  def DenseMatrix currentPoint()
  def double evaluate()
  def Optional<Double> evaluationStandardError() 
  def DenseMatrix gradient()
  def Map<String,Double> monitors()
  def String description()
  def double budget()
}