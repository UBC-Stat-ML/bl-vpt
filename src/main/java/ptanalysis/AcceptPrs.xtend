package ptanalysis

import java.util.List
import java.io.File
import java.util.LinkedHashMap
import briefj.BriefIO
import blang.engines.internals.factories.PT
import briefj.BriefMaps
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import java.util.ArrayList
import java.util.Collections
import java.util.Random

class AcceptPrs {
  
  def static List<Double> equallySpacedAcceptPrs(LinkedHashMap<Double,List<Double>> energies, double targetAccept) {
    val annealParams = new ArrayList(energies.keySet)
    val result = new ArrayList
    var currentIndex = 0
    while (currentIndex < annealParams.size - 1) {
      val nextIndexAndAcceptPr = nextIndexAndAcceptPr(currentIndex, annealParams, energies, targetAccept)
      result.add(nextIndexAndAcceptPr.value)
      currentIndex = nextIndexAndAcceptPr.key
    }
    return result
  }
  
  def static Pair<Integer,Double> nextIndexAndAcceptPr(int startIndex, ArrayList<Double> params, LinkedHashMap<Double, List<Double>> map, double targetAccept) {
    val startParam = params.get(startIndex)
    var accept = Double.NaN
    for (nextIndex : (startIndex+1) ..< params.size) {
      val endParam = params.get(nextIndex)
      accept = estimateSwapPr(startParam, endParam, map.get(startParam), map.get(endParam))
      if (accept < targetAccept)
        return nextIndex -> accept
    }
    return params.size - 1 -> accept
  }
  
  def static double estimateSwapPr(double param1, double param2, List<Double> list1, List<Double> list2) {
    val summary = new SummaryStatistics
    val deltaParam = param1 - param2
    if (list1.size !== list2.size) throw new RuntimeException
    for (i : 0 ..< list1.size)
      summary.addValue(Math.exp(deltaParam * Math.min(0, list1.get(i) - list2.get(i))))
    return summary.getMean 
  }
  
  def static LinkedHashMap<Double,List<Double>> preprocessedEnergies(File f) {
    val result = _loadEnergies(f)
    _burnInShuffle(result, 0.2, new Random(1))
    return result
  }
  
  def static _burnInShuffle(LinkedHashMap<Double, List<Double>> map, double burnInRate, Random rand) {
    for (key : new ArrayList(map.keySet)) {
      val list = map.get(key)
      val postBurnIn = list.subList((burnInRate * list.size) as int, list.size)
      Collections.shuffle(postBurnIn, rand)
      map.put(key, postBurnIn)
    }
  }
  
  /**
   * Input: see samples/energy.cvs in MCMC output for example
   * 
   * Returned key: annealing parameter (0=prior)
   *          value: list of energy samples
   * 
   * Key are ordered from 1.0 to 0.0
   */
  def private static LinkedHashMap<Double,List<Double>> _loadEnergies(File f) {
    val result = new LinkedHashMap<Double,List<Double>>
    for (line : BriefIO.readLines(f).indexCSV) {
      val annealParam = Double::parseDouble(line.get(PT::annealingParameterColumn))
      val value = Double::parseDouble(line.get("value"))
      BriefMaps.getOrPutList(result, annealParam).add(value)
    }
    return result
  }
}