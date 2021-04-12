package opt

import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Data
import xlinear.AutoDiff.Differentiable
import static extension xlinear.AutoDiff.*
import java.util.List
import org.apache.commons.math3.analysis.differentiation.DerivativeStructure
import java.util.Random
import xlinear.AutoDiff
import blang.core.RealDistribution
import blang.distributions.Normal

import static blang.types.StaticUtils.*
import blang.types.StaticUtils
import xlinear.MatrixOperations
import java.util.Collections

class TestObjectives {
  
  def static quadratic() {
    return new Toy(MatrixOperations::denseCopy(#[100.0])) [
      val x = get(0)
      return x.pow(2)
    ]
  }
  
  
  def static rosenbrock(int d) {
    return new Toy(MatrixOperations::dense(d)) [
      var sum = new DerivativeStructure(it.size, 1, 0.0)
      val one = new DerivativeStructure(it.size, 1, 1.0)
      for (i : 0 ..< d - 1) {
        sum += 100 * (get(i+1) - get(i).pow(2)).pow(2) + (get(i) - one).pow(2)
      }
      return sum
    ]
  }
  
  static class Toy implements Objective {
    
    val Differentiable function
    val Random rand = new Random(1)
    val RealDistribution evalNoise = Normal::distribution(fixedReal(0.0), fixedReal(0.01))
    val RealDistribution gradNoise = Normal::distribution(fixedReal(0.0), fixedReal(0.01))
    var DenseMatrix currentPoint
    
    new (DenseMatrix currentPoint, Differentiable function) { 
      this.function = function
      this.currentPoint = currentPoint
    }
    
    override moveTo(DenseMatrix updatedParameter) {
      this.currentPoint = updatedParameter
    }
    
    override currentPoint() {
      currentPoint
    }
    
    override evaluate() {
      val diff = AutoDiff::autoDiff(currentPoint, function)
      return diff.value + evalNoise.sample(rand)
    }
    
    override gradient() {
      val grad = AutoDiff::gradient(currentPoint, function)
      for (i : 0 ..< grad.nEntries)
        grad.set(i, grad.get(i) + gradNoise.sample(rand))
      return grad
    }
    
    override monitors() {
      Collections.emptyMap
    }
    
    override description() {
      "Toy"
    }
  }
  
}