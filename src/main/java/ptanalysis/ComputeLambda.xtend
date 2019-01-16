package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg

class ComputeLambda extends Experiment {
  @Arg Energies energies
  
  
  override run() {
    for (beta : (0 .. 1000).map[it / 1000.0])
      results.getTabularWriter("lambda").write(
        "beta" -> beta,
        "ref" -> ref(beta),
        "lambda" -> energies.lambda(beta),
        "swap" -> energies.swapAcceptPr(0.0, beta)
      )
  }
  
  def static double ref(double beta) {
    val a = 1e6
    return 2 * Math.pow(a, beta) * Math.log(a) / Math.pow(1 + 2 * Math.pow(a, beta), 2)
  }
  
  static def void main(String [] args) { Experiment::startAutoExit(args) }
}