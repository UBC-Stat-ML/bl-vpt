package ptgrad

import blang.inits.experiments.Experiment
import blang.runtime.Runner
import ptgrad.ConjugateNormal
import ptgrad.Variational
import ptgrad.VariationalPT
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import is.DiagonalHalfSpaceImportanceSampler
import bayonet.math.NumericalUtils
import ptgrad.ToyNormal
import ptgrad.TemperingObjective
import ptanalysis.PTGradientTest

class ToyNormalTest extends Experiment {
  
  override run() {
    val runner = Runner::create(results.resultsFolder,
      "--model", Variational.canonicalName, 
      "--model.interpolation", ToyNormal.canonicalName,
      "--engine", "ptgrad.VariationalPT",
      "--engine.pt.nPassesPerScan", "20",
      "--engine.pt.nChains", "2",
      "--engine.optimize", "false"
    )
    val vpt = runner.engine as VariationalPT
    
    runner.run()
    
    var delta = 0.1
    vpt.parameters.set(0, delta)
    
    val objective = new TemperingObjective(vpt)  
    println("obj " + objective.evaluate + " " + PTGradientTest::analyticRejectRate(delta))
    
    println("grad " + objective.gradient.get(0) + " " + PTGradientTest::analyticRejectGradient(delta))
    

  }
  

  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}