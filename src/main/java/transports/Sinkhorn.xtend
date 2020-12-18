package transports

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import xlinear.Matrix
import xlinear.DenseMatrix
import bayonet.math.NumericalUtils
import org.eclipse.xtend.lib.annotations.Data
import bayonet.math.CoordinatePacker
import briefj.collections.UnorderedPair
import java.util.List

class Sinkhorn {
  
  val Matrix pi
  val Matrix exponentiatedCosts
  val Matrix costs
  public val Matrix result
  
  def n() { pi.nEntries }
  
  
  
  new(Matrix pi, Matrix costs, double lambda, int maxIters, double relativeTolerance) {
    NumericalUtils::checkIsClose(1.0, pi.sum)
    StaticUtils::checkPositiveSymmetric(costs)
    this.costs = costs
    this.pi = pi
    if (costs.nRows !== n || costs.nCols !== n)
      throw new RuntimeException
    this.exponentiatedCosts = dense(n, n)
    for (i : 0 ..< n)
      for (j : 0 ..< n)
        exponentiatedCosts.set(i, j, Math::exp(-lambda * costs.get(i, j)))
        
    var u = ones(n)
    var v = ones(n)
    var converged = false
    var previousCost = 0.0
    var Matrix computedResult = null
    for (var int iter = 0; iter < maxIters && !converged; iter++) {
      u = update(v)
      v = update(u)
      computedResult = computeResult(u, v)
      val currentCost = StaticUtils::cost(computedResult, costs)
      val delta = Math::abs(currentCost - previousCost) / currentCost
      println("" + iter + "\t" + delta)
      if (delta < relativeTolerance) {
        converged = true
      }
      previousCost = currentCost
    }
    if (!converged)
      System.err.println("Sinkhorn did not converge")
    
    result = computedResult
    checkMarginals
  }
  
  def computeResult(DenseMatrix u, DenseMatrix v) {
    val result = dense(n, n)
    for (i : 0 ..< n) 
      for (j : 0 ..< n)
        result.set(i, j, u.get(i) * v.get(j) * exponentiatedCosts.get(i, j))
    result /= result.sum
    return result
  }
  
  def DenseMatrix update(Matrix previous) {
    val result = dense(previous.nEntries)
    val product = exponentiatedCosts * previous
    for (i : 0 ..< result.nEntries)
      result.set(i, pi.get(i) / product.get(i))
    result /= result.sum
    return result
  }
  
  def checkMarginals() {
    StaticUtils::checkMarginals(result, pi)
    StaticUtils::checkMarginals(result.transpose, pi)
  }
  
  //// Baselines
  
  def Matrix gibbsJoint() {
    return pi * pi.transpose
  }
  
  def Matrix peskun() {
    val it = dense(n, n) 
    for (i : 0 ..< n) 
      for (j : 0 ..< n) 
        if (i !== j)
          set(i, j, pi.get(i) * peskunTransition(i, j))
    for (i : 0 ..< n) {
      var sum = 0.0
      for (j : 0 ..< n)
        if (j !== i) 
          sum += peskunTransition(i, j)
      set(i, i, pi.get(i) * Math.max(0.0, 1.0 - sum))
    }
    it /= it.sum // fix numerical issue
    return it
  }
  
  def double peskunTransition(int i, int j) {
    val q = pi.get(j) / (1.0 - pi.get(i))
    val r = Math::min(1.0, (1.0 - pi.get(i)) / (1.0 - pi.get(j)))
    return q * r
  }
  
//  def static double expectedPeskunBernoulli(double p) {
//    val pi = #[p]
//    val product = new Product(pi)
//    val sink = new Sinkhorn(product.pi, product.costs, 10.0, 1)
//    val pesk = sink.peskun
//    return sink.totalCost(pesk)
//  }
  
  
  def static void main(String [] args) {
    
//    val eps = 0.1
//    var bestRatio = Double.POSITIVE_INFINITY
//    for (var double p1 = eps; p1 <= 1.0 - eps; p1 += eps)
//      for (var double p2 = eps; p2 <= p1; p2 += eps) { 
//        val product = new Product(#[p1, p2])
//        val pi = product.pi
//        val costs = product.costs
//        println("" + p1 + ", " + p2)
//        val currentRatio = report(pi, costs, 10.0)
//        if (currentRatio < bestRatio)
//          bestRatio = currentRatio
//          
//        println("Decomposed pesk=" + (expectedPeskunBernoulli(p1) + expectedPeskunBernoulli(p2)))
//          
//        println("---")
//      }
//      
//    println("best=" +bestRatio)
//    
//    println("Basic MH example")
//    val pi = denseCopy(#[0.2, 0.8])
//    val costs = denseCopy(#[
//      #[1, 0],
//      #[0, 1]
//    ])
//    report(pi, costs, 10.0)
//    
    println("Ising example")    
    val ising = new Ising(3)
    val sink = new Sinkhorn(ising.pi, ising.costs, 10.0, 1000, 1e-4)
    sink.report()
  }
  
  
  def report() {

//    val sCost = totalCost(result)
//    println("Sink: " + sCost)
//    
//    val gibbs = gibbsJoint
//    println("Gibbs: " + totalCost(gibbs))
//    StaticUtils::checkMarginals(gibbs, pi)
//    
//    val peskun = peskun
//    val pCost = totalCost(peskun)
//    println("Peskun: " + pCost)
    // checkMarginals(pi, peskun)
    
  }
  
}