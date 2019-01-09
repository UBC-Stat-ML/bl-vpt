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
  
  override double swapAcceptPr(double param1, double param2) {
    _swapAcceptPr(Math::min(param1, param2), Math::max(param1, param2))
  }
  
  def private double _swapAcceptPr(double param1, double param2) {
    if (param1 === param2) return 1.0
    var prop1 = findProposal(param1)
    var prop2 = findProposal(param2)
    if (prop1 === prop2) {
      prop1 = energies.floorKey(param1)
    }
    return integrate(param1, prop1, param2, prop2, [e1, e2 | Math::min(1, Math::exp((param2 - param1) * (e2 - e1)))])
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
  
  def private double integrate(double targetParam1, double proposalParam1, double targetParam2, double proposalParam2, (double, double) => double integrand) {
    var num = 0.0
    var denom = 0.0
    val list1 = energies.get(proposalParam1)
    val list2 = energies.get(proposalParam2)
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