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
import java.util.Random

class BipartiteSwapExperiment extends Experiment {
  
  @Arg File exec
  
  @Arg @DefaultValue("2") int nPerComponent = 2
  
  @Arg @DefaultValue("1") Random rand = new Random(1)
  
  @Arg @DefaultValue("false") boolean useWass = false
  
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
      .mapValues[map[value]]
    val nSamples = chain2samples.values.head.size
    println("Loaded " + nSamples + " post burn-in samples")
    
    var sumInefficiencies = 0.0
    var sumLambda = 0.0
    for (chain : 0 ..< nChains - 1) {
      val transportStats = new SummaryStatistics
      val samples0 = new ArrayList(chain2samples.get(chain))
      val samples1 = new ArrayList(chain2samples.get(chain + 1))
      Collections::shuffle(samples0, rand)
      Collections::shuffle(samples1, rand)
      for (sample : 0 ..< nSamples - nPerComponent) {
        
        
        if (useWass) {
          
          // sort
          val subList0 = new ArrayList(samples0.subList(sample, sample + nPerComponent))
          val subList1 = new ArrayList(samples1.subList(sample, sample + nPerComponent))
          Collections::sort(subList0)
          Collections::sort(subList1)
          
          var deltaE = 0.0
          for (int i : 0 ..< subList0.size) {
            deltaE += subList0.get(i) - subList1.get(i)
          }
          val ratio = (chain2param.get(chain) - chain2param.get(chain + 1)) * deltaE
          val accept = Math::min(1.0, Math::exp(ratio))
          val reject = 1.0 - accept
          transportStats.addValue(reject) 
          
        } else {
          
          val energies = new ArrayList<Double> => [
            addAll(samples0.subList(sample, sample + nPerComponent))
            addAll(samples1.subList(sample, sample + nPerComponent))
          ]
        
          val logWeights = logWeights(energies, #[chain2param.get(chain), chain2param.get(chain + 1)])
          val bipartiteSwap = new BipartiteSwapTransport(logWeights)
          val plan = (new SimplexSolver).solve(bipartiteSwap.transport)
          transportStats.addValue(plan.cost/nPerComponent) 
        
        }
        
      }
      val r =  transportStats.mean
      sumLambda += r
      sumInefficiencies +=  r / (1.0 - r)
      println("" + chain + "\t" + r) 
    }
    results.getTabularWriter("results").printAndWrite(
        "asymptoticBarrier" -> sumLambda,
        "barrier" -> sumInefficiencies
      )
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