package ptanalysis

import java.util.TreeMap
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import blang.inits.DesignatedConstructor
import java.io.File
import bayonet.distributions.Random
import java.util.Collections
import blang.inits.ConstructorArg
import blang.inits.DefaultValue
import java.util.HashMap

@Data
class MCEnergies implements Energies {
  val TreeMap<Double, List<Double>> energies
  
  @DesignatedConstructor
  def static MCEnergies load(
    @ConstructorArg("file") File file, 
    @ConstructorArg("burnInRate") @DefaultValue("0.5") double burnInRate, 
    @ConstructorArg("maxNSamples") @DefaultValue("INF") int maxNSamples
  ) {
    val energies = SwapStaticUtils::loadEnergies(file)
    SwapStaticUtils::_burnIn(energies, burnInRate)
    val rand = new Random(1)
    for (key : energies.keySet) {
      val list = energies.get(key)
      Collections::shuffle(list, rand)
      if (maxNSamples < list.size)
        energies.put(key, list.subList(0, maxNSamples))
    }
    return new MCEnergies(new TreeMap(energies))
  }
  
  val lambdaCache = new HashMap<Double,Double>
  
  override lambda(double targetParam) {
    if (lambdaCache.containsKey(targetParam))
      return lambdaCache.get(targetParam)
    val proposalParam = findProposal(targetParam)
    val list = energies.get(proposalParam)
    val blockSize = list.size / 2
    val subList1 = list.subList(0, blockSize)
    val subList2 = list.subList(blockSize, 2*blockSize)
    val result = integrate(
      targetParam, proposalParam,
      targetParam, proposalParam,
      subList1,
      subList2,
      [e1, e2 | Math::abs(e1 - e2)]
    )
    lambdaCache.put(targetParam, result)
    return result
  }
  
  override double swapAcceptPr(double param1, double param2) {
    _swapAcceptPr(Math::min(param1, param2), Math::max(param1, param2))
  }
  
  def private double _swapAcceptPr(double param1, double param2) {
    if (param1 === param2) return 1.0
    var prop1 = findProposal(param1)
    var prop2 = findProposal(param2)
    if (prop1 === prop2) 
      prop1 = energies.floorKey(param1)
    return integrate(
      param1, prop1, 
      param2, prop2, 
      energies.get(prop1), 
      energies.get(prop2), 
      [e1, e2 | Math::min(1, Math::exp((param2 - param1) * (e2 - e1)))]
    )
  }
  
  def private double findProposal(double targetParam) {
    val after = energies.ceilingKey(targetParam)
    val before = energies.floorKey(targetParam)
    if (after === null) return before
    if (before === null) return after
    val d1 = after - targetParam
    val d2 = targetParam - before
    return if (d1 <= d2) after else before
  }
  
  def private double integrate(
    double targetParam1, double proposalParam1, 
    double targetParam2, double proposalParam2, 
    List<Double> list1,
    List<Double> list2,
    (double, double) => double integrand
  ) {
    var num = 0.0
    var denom = 0.0
    if (list1.size !== list2.size) throw new RuntimeException
    for (i : 0 ..< list1.size) {
      val energy1 = list1.get(i) 
      val energy2 = list2.get(i)
      val weight =
        weight(targetParam1, proposalParam1, energy1) * 
        weight(targetParam2, proposalParam2, energy2)
      num += weight * integrand.apply(energy1, energy2)
      denom += weight
    }
    return num / denom
  }
  
  def private static double weight(double targetParam, double proposalParam, double energy) {
    return Math::exp((proposalParam - targetParam) * energy)
  }
}