package is

import java.util.Collections
import java.util.TreeSet
import org.eclipse.xtend.lib.annotations.Data
import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*

import static extension xlinear.MatrixExtensions.*
import java.util.ArrayList
import briefj.BriefIO
import briefj.BriefLog
import java.util.TreeMap

import static extension java.lang.Math.*

/**
   * 
   * samples1 = {(f1_i, G1_i)}
   * samples2 = {(f2_j, G2_j)}
   * 
   * where G1 is a vector and G2 a constant or vice versa
   * 
   * Computes  
   * sum_i sum_j I[f1_i > f2_j] G1_i w1_i G2_j w2_j
   * in n log n, where n is the max size of the 2 lists
   * 
   * if strict is false, then instead uses f1_i >= f2_j
   */
@Data
class DiagonalHalfSpaceImportanceSampler<T1, T2> extends ImportanceSampler  {
  
  val Iterable<T1> samples1
  val (T1)=>Double f1
  val (T1)=>DenseMatrix G1
  val (T1)=>Double weightFunction1
  
  val Iterable<T2> samples2
  val (T2)=>Double f2
  val (T2)=>DenseMatrix G2
  val (T2)=>Double weightFunction2
  
  val boolean strict
  
  private static def <T> double weightedSum(Iterable<T> samples, (T)=>Double weightFunction, int weightPower) {
    return samples.map[pow(weightFunction.apply(it), weightPower)].reduce[x,y|x+y]
  }
  
  override weightedSum(int weightPower, int functionPower) {
    
    
    if (functionPower === 0) {
      val double result = 
        weightedSum(samples1, weightFunction1, weightPower) * 
        weightedSum(samples2, weightFunction2, weightPower) 
      return denseCopy(#[result])
    }
    
    val sorted = new TreeMap<CumulativeSum,CumulativeSum>()
    for (sample2 : samples2) {
      val function = G2.apply(sample2)
      val weight = weightFunction2.apply(sample2)
      val current = function.pointwise[pow(functionPower)] * pow(weight, weightPower)
      val key = new CumulativeSum(f2.apply(sample2), current)
      if (sorted.containsKey(key)) sorted.get(key).entry += current
      else sorted.put(key, key)
    }
    
    var DenseMatrix sum = null
    for (it : sorted.keySet) { 
      if (sum === null)
        sum = entry
      else
        sum += entry
      cumulativeSum = sum.copy
    }
    
    var DenseMatrix result = null
    for (it : samples1) {
      val cumsum = 
        if (strict)
          sorted.lowerKey(new CumulativeSum(f1.apply(it), null))
        else 
          sorted.floorKey(new CumulativeSum(f1.apply(it), null))
      if (cumsum === null) {
        // nothing to do, this first group of terms is killed by the indicator
      } else {
        val function = G1.apply(it)
        val weight = weightFunction1.apply(it)
        val current = function.pointwise[pow(functionPower)] * pow(weight, weightPower) * cumsum.cumulativeSum
        if (result === null)
          result = current
        else
          result += current
      }
    }
    if (result === null) {
      val nRows = G1.apply(samples1.head).nRows
      val nCols = G2.apply(samples2.head).nCols
      return dense(nRows, nCols) 
    }
    
    return result
  }
  
  private static class CumulativeSum implements Comparable<CumulativeSum> {
    val Double f2

    var DenseMatrix cumulativeSum
    val DenseMatrix entry
    new (double f2, DenseMatrix entry) {
      this.f2 = f2
      this.entry = entry
    }
    
    override compareTo(CumulativeSum another) {
      this.f2.compareTo(another.f2)
    }
  }
  
  def StandardImportanceSampler<Pair<T1,T2>> asCosltyStandardSampler() {
    val zero = denseCopy(#[0.0])
    StandardImportanceSampler::productSampler(samples1, weightFunction1, samples2, weightFunction2) [ 
        val s1 = key
        val s2 = value
        if (f1.apply(s1) > f2.apply(s2) || (!strict && f1.apply(s1) == f2.apply(s2))) G1.apply(s1) * G2.apply(s2) else zero
      ]
  }
  
  def StandardImportanceSampler<Pair<T1,T2>> asNaiveStandardSampler() {
    val paired = new ArrayList<Pair<T1,T2>>()
    val list1 = samples1.toList
    val list2 = samples2.toList
    for (i : 0 ..< Math::min(list1.size, list2.size))
      paired.add(list1.get(i) -> list2.get(i))
    val zero = denseCopy(#[0.0])
    return new StandardImportanceSampler(paired, 
      [
        val s1 = key
        val s2 = value
        if (f1.apply(s1) > f2.apply(s2) || (!strict && f1.apply(s1) == f2.apply(s2))) G1.apply(s1) * G2.apply(s2) else zero
      ],
      [
        val s1 = key
        val s2 = value
        weightFunction1.apply(s1) * weightFunction2.apply(s2)
      ]
    )
  }
  
  
  private def static <T> double ess(Iterable<T> samples, (T)=> DenseMatrix g, (T)=>Double weightFunction) {
    val is = new StandardImportanceSampler(samples, g, weightFunction)
    return is.ess
  }
    
  override ess() { 
    ess(samples1, G1, weightFunction1) + ess(samples2, G2, weightFunction2)
  }
  
  def DenseMatrix varianceEstimate() {
    val meanSq = estimate.pointwise[pow(2)]
    return estimate(2) - meanSq
  }
  
  override standardError() {
    // based on the heuristic formula var/(ess sample1 + ess sample2)
    // since the default one assumes a sample size of O(n^2) which 
    // is overoptimistic given the strong dependencies involved
    // NB: based on quick simulation in a1e58bea252dde26ba88d31b8b6ce39fe63996e8
    val varEstimate = varianceEstimate
    val ess = ess()
    return varEstimate.pointwise[sqrt(it/ess)]
  }
  
  def static void main(String [] args) {
    
    val samples1 = (3 .. 5).map[it as double as Double].toList => [Collections::shuffle(it) ]
    val samples2 = (1 .. 4).map[it as double as Double].toList => [Collections::shuffle(it) ]
    
    val w1 = [Double x | x + 1]
    val w2 = [Double x | x + 2]
    
    val f1 = [Double x | x] 
    val f2 = [Double x | x]
    
    val G1 = [Double x | denseCopy(#[x])]
    val G2 = [Double x | denseCopy(#[x])]
    
    val fancySampler = new DiagonalHalfSpaceImportanceSampler(
        samples1, f1,  G1, w1, 
        samples2, f2,  G2, w2, true
    )
    
    val naiveSampler = fancySampler.asNaiveStandardSampler
    
    println("fancy:" + fancySampler.estimate.get(0))
    println("naive:" + naiveSampler.estimate.get(0))
    
    for (j : 1 .. 2)
      for (i : 0 .. 3) {
      println("=== " + j + " " + i)
      println("fancy:" + fancySampler.weightedSum(j, i).get(0))
      
      
      
      
      println("naive:" + naiveSampler.weightedSum(j, i).get(0))
    }
  }
}