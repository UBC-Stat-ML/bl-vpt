package ptanalysis

import blang.types.AnnealingParameter
import blang.core.RealDistribution
import xlinear.Matrix
import xlinear.MatrixOperations
import java.util.Random

class Annealers {
  
  //for now, use Round, and create an inverse mapping from index to its round
  
  def static double zeno(double mu, AnnealingParameter param, Matrix partialSums, int n) {
    val beta = param.doubleValue
    if (beta == 0.0) return 0.0
    if (beta == 1.0) return mu * (partialSums.get(n) - 0.5 * n * mu)
    val double L = log(beta * n, 2)
    val int a = if (L < 0) 0 else Math::pow(2, Math::floor(L)) as int - 1
    val int b = if (L < 0) 1 else Math::pow(2, Math::ceil(L)) as int - 1
    val double lambda = (beta * n - a) / (b - a)
    val double sa = partialSums.get(a)
    val double sb = partialSums.get(b)
    // workaround to issue https://github.com/eclipse/xtext-xtend/issues/1005
    val double t1 = sa + lambda * (sb - sa)
    val double t2 = 0.5 * mu * (a + lambda * (b - a)) 
    return mu * (t1 - t2)
  }
  
  def static double log(double x, double b) {
    return Math::log(x) / Math::log(b)
  }
  
  def static double linear(double mu, AnnealingParameter param, Matrix partialSums, int n) {
    val beta = param.doubleValue
    if (beta == 0.0) return 0.0
    if (beta == 1.0) return mu * (partialSums.get(n) - 0.5 * n * mu)
    val int l = Math.floor(beta * n) as int
    val int u = l + 1
    val double xl = partialSums.get(u) - partialSums.get(l)
    val double lambda = n * beta - l
    val double sl = partialSums.get(l)
    return mu * (lambda * xl + sl - 0.5 * beta * n * mu)
  }
  
  def static Matrix generatePartialSums(Random rand, int n, RealDistribution dist) {
    val result = MatrixOperations::dense(n+1)
    result.set(0, 0)
    for (i : 1 .. n) {
      val sample = dist.sample(rand)
      result.set(i, result.get(i-1) + sample)
    }
    return result.readOnlyView
  }
  
  
  
//  def static void main(String [] args) {
//    val Random rand = new Random(1)
//    val int n = 121
//    val data = generatePartialSums(rand, n, Normal::distribution(fixedReal(0.0), fixedReal(1.0)))
//    val mu = 1.1
//    
//    val grid = 10000
//    for (i : 0 ..< grid) {
//      println(linear(n, mu, new AnnealingParameter => [_set(fixedReal(i as double / grid))], data))
//    }
//  }
}