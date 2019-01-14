package ptanalysis

import java.util.TreeMap
import org.eclipse.xtend.lib.annotations.Data
import org.apache.commons.math3.analysis.solvers.PegasusSolver
import java.util.List
import java.util.ArrayList

@Data
class QuantileSearch {
  val TreeMap<Double,Double> cumulativeIntegrals
  
  def static QuantileSearch fromDensity((double)=>double density, double left, double right, int nPoints) {
     val result = new QuantileSearch(new TreeMap)
     var integral = 0.0
     val delta = (right - left) / nPoints
     var xl = left
     result.cumulativeIntegrals.put(xl, 0.0)
     for (i : 0 ..< nPoints+1) {
       val xmid = xl + delta/2.0
       val y = density.apply(xmid)
       integral += y * delta
       if (i == nPoints)
         xl = right
       result.cumulativeIntegrals.put(xl, integral)
       xl += delta
     }
     return result
  }
  
  def double quantile(double p) {
    if (p == 0.0)
      return cumulativeIntegrals.firstEntry.key
    if (p == 1.0)
      return cumulativeIntegrals.lastEntry.key
    val (double)=>double objective = [x | cumulativeIntegral(x) / cumulativeIntegral - p]
    val solver = new PegasusSolver
    return solver.solve(100_000, objective, cumulativeIntegrals.firstEntry.key, cumulativeIntegrals.lastEntry.key)
  }
  
  /**
   * Returns a list of size n+1
   * 
   * E.g. n=4 gives quartiles p in (0, 1/4, 1/2, 3/4, 1) 
   */
  def List<Double> quantiles(int n) {
    val result = new ArrayList(n)
    for (i : 0 .. n)
      result.add(quantile((i as double) / n))
    return result
  }
  
  def double cumulativeIntegral() {
    return cumulativeIntegrals.lastEntry.value
  }
  
  def double cumulativeIntegral(double x) {
    if (cumulativeIntegrals.containsKey(x))
      return cumulativeIntegrals.get(x)
    val xl = cumulativeIntegrals.floorKey(x)
    val xr = cumulativeIntegrals.ceilingKey(x)
    val yl = cumulativeIntegrals.get(xl)
    val yr = cumulativeIntegrals.get(xr)
    return yl + (x - xl) * (yr - yl) / (xr - xl)
  }
}