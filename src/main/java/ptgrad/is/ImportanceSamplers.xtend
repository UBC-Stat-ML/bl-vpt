package ptgrad.is

import org.eclipse.xtend.lib.annotations.Data
import java.util.List
import org.eclipse.xtext.xbase.lib.Functions.Function1
import xlinear.DenseMatrix
import org.eclipse.xtext.xbase.lib.Functions.Function2
import static extension java.util.Collections.sort
import static java.util.Comparator.*
import java.util.TreeMap
import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*
import java.util.TreeSet
import java.util.function.Function

class ImportanceSamplers {
  
  def ImportanceSamplingEstimate univariate(Iterable<Sample> samples, Function1<Sample, DenseMatrix> function) {
    val result = new ImportanceSamplingEstimate
    for (sample : samples)
      result.add(function.apply(sample), sample.weight)
    return result
  }
  
  def ImportanceSamplingEstimate naiveBivariate(Iterable<Sample> samples1, Iterable<Sample> samples2, Function2<Sample, Sample, DenseMatrix> function) {
    val result = new ImportanceSamplingEstimate
    for (sample1 : samples1)
      for (sample2 : samples2)
        result.add(function.apply(sample1, sample2), sample1.weight * sample2.weight)
    return result
  }
  
  def ImportanceSamplingEstimate bivariateDiagonalHalfSum(
    Iterable<Sample> samples1, Iterable<Sample> samples2, 
    Function<Sample, Double> f, Function<Sample, Double> g,
    Function<Sample, DenseMatrix> H, Function<Sample, DenseMatrix> K) 
  {
      
  }
  

  private def DenseMatrix diagonalHalfSum(
    List<Pair<Double, DenseMatrix>> samples1, 
    List<Pair<Double, DenseMatrix>> samples2
  ) {
    val sorted = new TreeSet<CumulativeSumKey>(samples2.map[new CumulativeSumKey(it)])
    val dim = samples1.get(0).value.nEntries
    var current = dense(dim)
    for (it : sorted) {
      cumulativeSum += current
      current = cumulativeSum
    }
    current = dense(dim)
    for (sample1 : samples1) {
      val prefixKey = sorted.lower(new CumulativeSumKey(sample1))
      if (prefixKey !== null)
        current += sample1.value * prefixKey.cumulativeSum
    }
    return current
  }
  
  
  
  
}