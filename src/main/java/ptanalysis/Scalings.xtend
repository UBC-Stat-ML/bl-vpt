package ptanalysis

import java.io.File
import blang.inits.experiments.Experiment

class Scalings extends Experiment {
  
  override run() {
    val writer = results.getTabularWriter("output")
    val energies = AcceptPrs::preprocessedEnergies(new File("/Users/bouchard/experiments/blang-mixture-tempering/work/55/1fdcf66051e25fba133d3be2af06d2/results/all/2018-11-13-22-28-19-LplqtyMI.exec/samples/energy.csv"))
    for (target : (0..10).map[it as double/10.0]) {
      val acceptPrs = AcceptPrs::equallySpacedAcceptPrs(energies, target)
      println("Accept prs targeting " + target + ":" + acceptPrs)
      for (reversible : #[true, false]) {
        val mc = new TemperatureProcess(acceptPrs, reversible)
        val absorb = new AbsorptionProbabilities(mc)
        writer.write(
          "reversible" -> reversible,
          "targetAccept" -> target,
          "nChains" -> (acceptPrs.size + 1),
          "rejuvenationPr" -> absorb.absorptionProbability(mc.initialState, mc.absorbingState(1)) 
        )
      }
    }
  } 
  
  def static void main(String [] args) {
    Experiment::start(args)
  }
}