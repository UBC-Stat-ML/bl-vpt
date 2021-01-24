package ptgrad

import org.jblas.DoubleMatrix

/**
 * Assume the objective function is of the form
 */
interface Objective {
  
  def double evaluate(Interpolation first, Interpolation second)
  
}