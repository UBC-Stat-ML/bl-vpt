package opt

import xlinear.DenseMatrix
import java.util.Map

/**
 * By default, minimization is considered
 */
interface Objective {
  def void moveTo(DenseMatrix updatedParameter)
  def DenseMatrix currentPoint()
  def double evaluate()
  def DenseMatrix gradient()
  def Map<String,Double> monitors()
  def String description()
}