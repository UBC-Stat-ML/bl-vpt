package ptgrad

import java.util.List
import blang.core.LogScaleFactor
import org.apache.commons.math3.analysis.differentiation.DerivativeStructure
import java.util.Set
import java.util.ArrayList

class Utils {
  
  def static double logDensity(List<LogScaleFactor> target) {
    var sum = 0.0
    for (factor : target) {
      val current = factor.logDensity
      if (current == Double.NEGATIVE_INFINITY) 
        return Double.NEGATIVE_INFINITY
      sum += current
    }
    return sum
  }
  
  def static List<String> parameterComponents(Set<String> variableNames) {
    var result = new ArrayList
    for (variableName : variableNames) {
      for (type : VariationalParameterType.values) {
        result.add(type.paramName(variableName))
      }
    }
    return result
  }
  
}