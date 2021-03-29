package ptgrad


import static xlinear.MatrixOperations.*
import static extension java.lang.Math.*
import static extension xlinear.MatrixExtensions.*

import static extension xlinear.AutoDiff.*

import org.apache.commons.math3.analysis.differentiation.DerivativeStructure

class VariationalFactors {
  
  def static DerivativeStructure normalLogDensity(DerivativeStructure x, DerivativeStructure mean, DerivativeStructure variance) {
    return - 0.5 * variance.log - log(2*PI) / 2.0 - 0.5 * (mean - x).pow(2) / variance
  }
  
  def static DerivativeStructure logNormalLogDensity(DerivativeStructure x, DerivativeStructure mean, DerivativeStructure variance) {
    return - 0.5 * variance.log - x.log - log(2*PI) / 2.0 - 0.5 * (mean - x.log).pow(2) / variance
  }
  
}