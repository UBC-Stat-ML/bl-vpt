package is

import org.eclipse.xtext.xbase.lib.Functions.Function1
import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Data

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*
import java.util.List
import java.util.ArrayList

import static extension java.lang.Math.*

@Data
class StandardImportanceSampler<T> extends ImportanceSampler {
  
  val Iterable<T> samples
  val (T)=>DenseMatrix function
  val (T)=>Double weightFunction
  
  override weightedSum(int weightPower, int functionPower) {
    var DenseMatrix result = null
    for (sample : samples) {
      val point = function.apply(sample)
      val weight = weightFunction.apply(sample)
      if (result === null) {
        result = dense(if (functionPower === 0) 1 else point.nEntries)
      }
      for (i : 0 ..< result.nEntries) {
        result.set(i, result.get(i) + pow(weight, weightPower) * pow(point.get(i), functionPower))
      }
    }
    return result
  }
  
  def static <T1,T2> StandardImportanceSampler<Pair<T1,T2>> productSampler(
    Iterable<T1> samples1, (T1)=>Double weightFunction1,
    Iterable<T2> samples2, (T2)=>Double weightFunction2,
    (Pair<T1,T2>)=>DenseMatrix function) {
    val productList = new ArrayList<Pair<T1,T2>>()
    for (sample1 : samples1)
      for (sample2 : samples2)
        productList.add(Pair.of(sample1, sample2))
    return new StandardImportanceSampler<Pair<T1,T2>>(productList, function, [weightFunction1.apply(key) * weightFunction2.apply(value)])
  }
}