package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg
import java.util.Optional
import blang.inits.DefaultValue

class RejuvationEstimates extends Experiment {
  @Arg  @DefaultValue("false") 
  boolean reversible = false
  
  @Arg 
  @DefaultValue("1")
  int  nHotChains = 1
  
  @Arg Optional<Paths> swapIndicators
  @Arg Optional<NormalEnergies> energies
  
  override run() {
    if (swapIndicators.present) {
      record("empirical", swapIndicators.get.nRejuvenations as double / swapIndicators.get.nIterations)
      record("empiricalInverseCycleTime", swapIndicators.get.nChains / swapIndicators.get.cycleTimeStatistics.mean)
    }
    if (energies.present)
      record("normalApprox", normalApproximation(energies.get))
  }
  
  def double normalApproximation(NormalEnergies energies) {
    val opt = new GridOptimizer(energies, reversible, nHotChains)
    opt.initialize(energies.moments.keySet)
    return opt.rejuvenationPr / 2.0 // divide by 2.0 since only half of odd-even moves have an opportunity to rejuvenate
  }
  
  def void record(String method, double rejuvenationRate) {
    results.getTabularWriter("output").write(
      "method" -> method,
      "rejuvenationRate" -> rejuvenationRate) 
  }
  
  static def void main(String [] args) { Experiment::startAutoExit(args) }
}