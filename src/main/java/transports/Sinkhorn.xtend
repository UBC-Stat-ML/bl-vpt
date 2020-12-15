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
  
  def totalCost(Matrix joint) {
    NumericalUtils.checkIsClose(1.0, joint.sum)
    var sum = 0.0
    for (i : 0 ..< n)
      for (j : 0 ..< n)
        if (joint.get(i,j) < 0) {
          if (joint.get(i,j) < -NumericalUtils::THRESHOLD)
            throw new RuntimeException("" + joint.get(i,j))
        }
        else sum += joint.get(i,j) * costs.get(i,j)
    return sum
  }
  
  new(Matrix pi, Matrix costs, double lambda, int nIters) {
    NumericalUtils::checkIsClose(1.0, pi.sum)
    checkSymmetric(costs)
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
    for (i : 0 ..< nIters) {
      u = update(v)
      v = update(u)
    }
    
    result = dense(n, n)
    for (i : 0 ..< n) 
      for (j : 0 ..< n)
        result.set(i, j, u.get(i) * v.get(j) * exponentiatedCosts.get(i, j))
    result /= result.sum
  }
  
  def checkSymmetric(Matrix matrix) {
    for (i : 0 ..< matrix.nRows)
      for (j : 0 ..< matrix.nCols)
        NumericalUtils::checkIsClose(matrix.get(i,j), matrix.get(j,i))
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
    checkMarginals(pi, result)
    checkMarginals(pi, result.transpose)
  }
  
  def static checkMarginals(Matrix pi, Matrix joint) {
    val marginal = joint * ones(joint.nRows)
    for (i : 0 ..< joint.nRows)
      NumericalUtils::checkIsClose(marginal.get(i), pi.get(i))
  }
  
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
  
  def static double expectedPeskunBernoulli(double p) {
    val pi = #[p]
    val product = new Product(pi)
    val sink = new Sinkhorn(product.pi, product.costs, 10.0, 1)
    val pesk = sink.peskun
    return sink.totalCost(pesk)
  }
  
  
  def static void main(String [] args) {
    
    val eps = 0.1
    var bestRatio = Double.POSITIVE_INFINITY
    for (var double p1 = eps; p1 <= 1.0 - eps; p1 += eps)
      for (var double p2 = eps; p2 <= p1; p2 += eps) { 
        val product = new Product(#[p1, p2])
        val pi = product.pi
        val costs = product.costs
        println("" + p1 + ", " + p2)
        val currentRatio = report(pi, costs, 10.0)
        if (currentRatio < bestRatio)
          bestRatio = currentRatio
          
        println("Decomposed pesk=" + (expectedPeskunBernoulli(p1) + expectedPeskunBernoulli(p2)))
          
        println("---")
      }
      
    println("best=" +bestRatio)
    
    println("Basic MH example")
    val pi = denseCopy(#[0.2, 0.8])
    val costs = denseCopy(#[
      #[1, 0],
      #[0, 1]
    ])
    report(pi, costs, 10.0)
    
    println("Ising example")    
    val ising = new Ising(3)
    report(ising.pi, ising.costs, 1.0)
  }
  
  static class Product extends Target {
    val double [] prs  // Bernoulli parameters
    
    def n() { prs.length }
    
    new(double [] prs) {
      super({
        val int[] sizes = newIntArrayOfSize(prs.length)
        for (v : 0 ..< prs.length) 
          sizes.set(v, 2)
        new CoordinatePacker(sizes)
      })
      this.prs = prs
    }
    
    def double pr(int p, int [] s) {
      if (s.get(p) === 1) return prs.get(p)
      else if (s.get(p) === 0) return 1.0 - prs.get(p)
      else throw new RuntimeException
    }
    
    override gamma(int[] s) {
      var it = 1.0
      for (p : 0 ..< n)
        it *= pr(p, s)
      return it
    }
    
    override cost(int[] s1, int[] s2) {
      intersectionSize(s1, s2)
    }
  }
  
  
  @Data
  static abstract class Target {
    val CoordinatePacker indexer
    def double gamma(int [] s)
    def double cost(int [] s1, int [] s2) 
    def pi() {
      val it = dense(indexer.size)
      for (i : 0 ..< indexer.size)
        set(i, gamma(unpack(i)))
      it /= sum
      return it
    }
    def costs() {
      val it = dense(indexer.size, indexer.size)
      for (i : 0 ..< indexer.size) 
        for (j : 0 ..< indexer.size)
          set(i, j, cost(unpack(i), unpack(j)))
      return it
    }
    def unpack(int i) {
      indexer.int2coord(i)
    }
  }
  
  @Data
  static class Ising extends Target {
    val int m
    val List<UnorderedPair<Integer, Integer>>  pairs
    val beta = Math::log(1 + Math::sqrt(2.0)) / 2.0 // critical point
    
    new (int m) {
      super({
        val int[] sizes = newIntArrayOfSize(m * m)
        for (v : 0 ..< m*m) 
          sizes.set(v, 2)
        new CoordinatePacker(sizes)
      })
      this.m = m
      pairs = blang.validation.internals.fixtures.Functions.squareIsingEdges(m)
    }
    
    override gamma(int [] s) {
      var sum = 0.0
      for (pair : pairs) {
        val first = s.get(pair.first)
        val second = s.get(pair.second)
        sum += (2*first-1)*(2*second-1)
      }
      return Math::exp(beta * sum)
    }
    
    override cost(int [] s1, int [] s2) {
      intersectionSize(s1, s2)
    }
  }
  
  def static double intersectionSize(int [] s1, int [] s2) {
    var sum = 0.0
      for (v : 0 ..< s1.length)  
        sum += if (s1.get(v) === s2.get(v)) 1.0 else 0.0
      return sum
  }
  
  def static double report(Matrix pi, Matrix costs, double lambda) {
    val it = new Sinkhorn(pi, costs, lambda, 100)
    checkMarginals()
    
    val sCost = totalCost(result)
    println("Sink: " + sCost)
    
    val gibbs = gibbsJoint
    println("Gibbs: " + totalCost(gibbs))
    checkMarginals(pi, gibbs)
    
    val peskun = peskun
    val pCost = totalCost(peskun)
    println("Peskun: " + pCost)
    // checkMarginals(pi, peskun)
    
    return sCost / pCost
  }
  
}