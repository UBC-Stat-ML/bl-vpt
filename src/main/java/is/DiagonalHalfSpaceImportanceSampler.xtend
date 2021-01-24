package is

import java.util.Collections
import java.util.TreeSet
import org.eclipse.xtend.lib.annotations.Data
import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*

import static extension xlinear.MatrixExtensions.*

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
  
  def DenseMatrix pow(DenseMatrix m, int p) {
    return m.copy => [editInPlace[_, __, v|Math::pow(v, p)]]
  }
  
  private static def <T> double weightedSum(Iterable<T> samples, (T)=>Double weightFunction, int weightPower) {
    return samples.map[Math::pow(weightFunction.apply(it), weightPower)].reduce[x,y|x+y]
  }
  
  override weightedSum(int weightPower, int functionPower) {
    var Pair<Integer,Integer> dims = 1 -> 1
    
    if (functionPower === 0) {
      val double result = 
        weightedSum(samples1, weightFunction1, weightPower) * 
        weightedSum(samples2, weightFunction2, weightPower) 
      return denseCopy(#[result])
    }
    
    val sorted = new TreeSet<CumulativeSum<T2>>()
    sorted.addAll(samples2.map[new CumulativeSum<T2>(f2.apply(it), it)])
    
    var DenseMatrix sum = null
    for (it : sorted) {
      val function = G2.apply(key)
      dims = updateDim(dims, 1, function.nCols) 
      val weight = weightFunction2.apply(key)
      val current = pow(function, functionPower) * Math::pow(weight, weightPower)
      if (sum === null)
        sum = current
      else
        sum += current
      cumulativeSum = sum.copy
    }
    
    var DenseMatrix result = null
    for (it : samples1) {
      val cumsum = sorted.lower(new CumulativeSum<T2>(f1.apply(it), null))
      if (cumsum === null) {
        // nothing to do, this first group of terms is killed by the indicator
      } else {
        val function = G1.apply(it)
        dims = updateDim(dims, 1, function.nCols)
        val weight = weightFunction1.apply(it)
        val current = pow(function, functionPower) * Math::pow(weight, weightPower) * cumsum.cumulativeSum
        if (result === null)
          result = current
        else
          result += current
      }
    }
    if (result === null)
      return dense(dims.key, dims.value) 
    
    return result
  }
  
  def updateDim(Pair<Integer,Integer> dims, int newRow, int newCol) {
    val nRows = Math::max(dims.key, newRow)
    val nCols = Math::max(dims.value, newCol)
    if (nRows > 1 && nCols > 1)
      throw new RuntimeException // when exponentiating that would not work
    return nRows -> nCols
  }
  
  private static class CumulativeSum<T2> implements Comparable<CumulativeSum<T2>> {
    val Double f2
    val T2 key
    var DenseMatrix cumulativeSum
    new (double f2, T2 key) {
      this.f2 = f2
      this.key = key
    }
    
    override compareTo(CumulativeSum<T2> another) {
      this.f2.compareTo(another.f2)
    }
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
        samples2, f2,  G2, w2
    )
    
    val zero = denseCopy(#[0.0])
    val naiveSampler = StandardImportanceSampler::naiveProductSampler(samples1, w1, samples2, w2) [ 
        val s1 = key
        val s2 = value
        if (f1.apply(s1) > f2.apply(s2)) G1.apply(s1) * G2.apply(s2) else zero
      ]
    
    println("fancy:" + fancySampler.estimate)
    println("naive:" + naiveSampler.estimate)
    
    for (j : 1 .. 2)
      for (i : 0 .. 3) {
      println("=== " + j + " " + i)
      println("fancy:" + fancySampler.weightedSum(j, i))
      
      
      
      
      println("naive:" + naiveSampler.weightedSum(j, i))
    }
  }
}