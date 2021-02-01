package opt

import xlinear.DenseMatrix

/**
 * By default, minimization is considered
 */
interface Objective {
  def void moveTo(DenseMatrix updatedParameter)
  def DenseMatrix currentPoint()
  def double evaluate()
  def DenseMatrix gradient()
}