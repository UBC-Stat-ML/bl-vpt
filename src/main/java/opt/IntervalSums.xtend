package opt

import java.util.ArrayList
import java.util.List
import java.util.Random
import bayonet.math.NumericalUtils

class IntervalSums {
  val cumsum = new ArrayList<Double>
  
  def void add(double d) { 
    val last = if (cumsum.empty) 0.0 else cumsum.last
    cumsum.add(last + d)
  }
  
  def size() {
    return cumsum.size
  }
  
  def double sum(int leftIncl, int rightExcl) {
    if (leftIncl === rightExcl) return 0.0
    if (leftIncl > rightExcl || leftIncl < 0 || rightExcl > cumsum.size)
      throw new RuntimeException
    val rightSum = cumsum.get(rightExcl - 1)
    val leftSum = if (leftIncl === 0) 0 else cumsum.get(leftIncl - 1)
    return rightSum - leftSum
  }
  
  def double average(int leftIncl, int rightExcl) {
    return sum(leftIncl, rightExcl) / (rightExcl - leftIncl)
  }
  
  
  ///// Tests
  
  private static def double naive(List<Double> values, int leftIncl, int rightExcl) {
    if (leftIncl === rightExcl) return 0.0
    values.subList(leftIncl, rightExcl).reduce[x,y|x+y]
  }
  
  def static void main(String [] args) {
    val list = new ArrayList<Double>
    val rand = new Random(1)
    val sums = new IntervalSums
    for (i : 0 .. 10) {
      val n = rand.nextGaussian
      list.add(n)
      sums.add(n)
    }
    
    for (i : 0 ..< list.size)
      for (j : (i) ..< list.size) {
        val naive = naive(list, i, j)
        val eff = sums.sum(i, j)
        println("" + naive + " vs " + eff)
        NumericalUtils.checkIsClose(naive, eff)
      }
  }
}