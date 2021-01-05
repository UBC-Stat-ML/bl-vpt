package transports

import blang.inits.Arg
import java.io.File 

import blang.inits.experiments.Experiment
import blang.inits.experiments.tabwriters.factories.CSV
import briefj.BriefIO
import java.util.LinkedHashMap
import java.util.Map
import blang.inits.DefaultValue
import java.util.Collections
import java.util.List
import java.util.ArrayList
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class BipartiteSwapExperiment extends Experiment {
  
  @Arg File exec
  
  @Arg @DefaultValue("2") int nPerComponent = 2
  
  override run() {
    // load annealingParam data (discard burn in)
    val monitoringFolder = new File(exec, "monitoring")
    val annealingParamFile = CSV::csvFile(monitoringFolder, "annealingParameters")
    var chain2param = BriefIO::readLines(annealingParamFile)
      .indexCSV
      .filter[get("isAdapt") == "false"]
      .uniqueIndex[chain]
      .mapValues[value]
    val _size = chain2param.size
    chain2param = new LinkedHashMap(chain2param) => [put(_size, 0.0)]
    val nChains = chain2param.size
    println("Loaded final schedule for " + nChains + " chains: " + chain2param)
    // load energy data
    val samplesFolder = new File(exec, "samples")
    val energyFile = CSV::csvFile(samplesFolder, "energy")
    val maxSample = BriefIO::readLines(energyFile).indexCSV.map[sample].max
    val burnIn = maxSample / 2
    val chain2samples = BriefIO::readLines(energyFile)
      .indexCSV
      .filter[sample > burnIn]
      .groupBy[chain]
      .mapValues[it.map[value]]
    val nSamples = chain2samples.values.head.size
    println("Loaded " + nSamples + " post burn-in samples")
    
    for (chain : 0 ..< nChains - 1) {
      val stats = new SummaryStatistics
      //Collections::shuffle(chain2samples.get(chain))
      //Collections::shuffle(chain2samples.get(chain + 1))
      for (sample : 0 ..< nSamples - nPerComponent) {
        val energies = new ArrayList<Double> => [
          addAll(chain2samples.get(chain    ).subList(sample, sample + nPerComponent))
          addAll(chain2samples.get(chain + 1).subList(sample, sample + nPerComponent))
        ]
        val logWeights = logWeights(energies, #[chain2param.get(chain), chain2param.get(chain + 1)])
        val bipartiteSwap = new BipartiteSwapTransport(logWeights)
        val plan = (new SimplexSolver).solve(bipartiteSwap.transport)
        stats.addValue(plan.cost/nPerComponent) 
//        val explicitLogRatio = (chain2param.get(chain) - chain2param.get(chain + 1)) * (energies.get(0) - energies.get(1))
//        val explicitRejPr = Math.min(1.0, Math.exp(explicitLogRatio))
//        println("" + explicitRejPr + " vs " + plan.cost)
      }
      println("" + chain + "\t" + stats.mean)
    }
  }
  
  def double [][] logWeights(List<Double> energies, List<Double> annealParams) {
    val it = newDoubleArrayOfSize(energies.size, 2)
    var int i = 0
    for (energy : energies) {
      set(i, 0, - annealParams.get(0) * energy)
      set(i, 1, - annealParams.get(1) * energy)
      i++
    }
    return it
  }
  
  def static int sample(Map<String,String> it) { Integer.parseInt(get("sample")) }
  def static int chain(Map<String,String> it) { Integer.parseInt(get("chain")) }
  def static double value(Map<String,String> it) { Double.parseDouble(get("value")) } 
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
  
}