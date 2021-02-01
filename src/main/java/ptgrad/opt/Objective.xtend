package ptgrad.opt

import xlinear.DenseMatrix

/**
 * Assume the objective function is of the form
 */
interface Objective {
  
  def void moveTo(DenseMatrix updatedParameter)
  
  def double evaluate()
  
  def DenseMatrix gradient()
  
}