package ptanalysis

import java.io.File
import blang.inits.experiments.Experiment
import blang.inits.Arg
import java.util.List
import java.util.ArrayList
import java.util.Set
import java.util.Collections
import blang.inits.experiments.tabwriters.TabularWriter

class CheckApproximationScalings extends Experiment {
  
  @Arg
  File energyFile
  
  override run() {
    val writer = results.getTabularWriter("output")
    val energies = SwapStaticUtils::preprocessedEnergies(energyFile)
    val normalApprox = new Energies(energyFile)
    for (target : (0..10).map[it as double/10.0]) {
      val indicesAndAcceptPrs = SwapStaticUtils::equallySpacedAcceptPrs(energies, target)
      val approxPrs = approxPrs(indicesAndAcceptPrs, normalApprox, energies.keySet)
      for (reversible : #[true, false]) {
        val curWriter = writer
          .child("reversible", reversible)
          .child("targetAccept", target)
          .child("nChains", (indicesAndAcceptPrs.size + 1))
        record("MC", new TemperatureProcess(indicesAndAcceptPrs.map[value].toList, reversible), curWriter)
        record("normalApprox", new TemperatureProcess(approxPrs, reversible), curWriter)
      }
    }
  }
  
  private static def void record(String method, TemperatureProcess process, TabularWriter writer) {
    val prs = new AbsorptionProbabilities(process)
    writer.write(
      "method" -> method,
      "value" -> prs.absorptionProbability(process.initialState, process.absorbingState(1)))
  }
  
  def List<Double> approxPrs(List<Pair<Integer,Double>> indicesAndAcceptPrs, Energies prs, Set<Double> annealParamsSet) {
    val annealParams = new ArrayList(annealParamsSet)
    Collections::sort(annealParams)
    val result = new ArrayList
    var currentAnnealParam = 0.0
    val writer = results.getTabularWriter("all-prs")
    for (indexAndPr : indicesAndAcceptPrs) {
      val nextAnnealParam = annealParams.get(indexAndPr.key)
      val approx = prs.swapAcceptPr(currentAnnealParam, nextAnnealParam)
      result.add(approx)
      currentAnnealParam = nextAnnealParam
      // report that accept pr for the two methods
      val mc = indexAndPr.value
      writer.write(
        "currentAnnealParam" -> currentAnnealParam,
        "nextAnnealParam" -> nextAnnealParam,
        "approx" -> approx,
        "mc" -> mc
      )
    }
    return result
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}