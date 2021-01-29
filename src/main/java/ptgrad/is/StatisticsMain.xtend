package ptgrad.is

import blang.inits.experiments.Experiment
import blang.runtime.Runner
import ptgrad.ConjugateNormal
import ptgrad.Variational
import ptgrad.VariationalPT
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class StatisticsMain extends Experiment {
  
  override run() {
    val runner = Runner::create(results.resultsFolder,
      "--model", Variational.canonicalName, 
      "--model.interpolation", ConjugateNormal.canonicalName,
      "--engine", "ptgrad.VariationalPT",
      "--engine.pt.nPassesPerScan", "20",
      "--engine.pt.nChains", "8" 
    )
    runner.run()
    val vpt = runner.engine as VariationalPT
    
    
    
    // next check: rejection rates correctly estimated
    val betas = vpt.betas
    val beta1 = betas.get(betas.size - 2)
    val beta2 = betas.get(betas.size - 1)
    for (nIters : (1 .. 3).map[Math::pow(10, it) as int]) {
      val fancyStats = new SummaryStatistics
      val naiveStats = new SummaryStatistics
      
      for (mc : 0 ..< 100) {
        val samples = vpt.iterate(nIters)
        val samples1 = samples.get(beta1)
        val samples2 = samples.get(beta2)
        
//        val expectedUntruncatedRatio = Statistics::expectedUntruncatedRatio(samples1, samples2, beta1, beta2)
//        val probabilityOfTruncation = Statistics::probabilityOfTruncation(samples1, samples2, beta1, beta2)
//        val expectedAccept = expectedUntruncatedRatio.estimate + probabilityOfTruncation.estimate
//        fancyStats.addValue(expectedAccept.get(0))

        val expectedGradient = Statistics::_expectedTruncatedGradient(samples1, samples2, beta1, beta2)
        fancyStats.addValue(expectedGradient.estimate.get(0))
    
        //val naive = expectedUntruncatedRatio.asNaiveStandardSampler.estimate + probabilityOfTruncation.asNaiveStandardSampler.estimate
        naiveStats.addValue(expectedGradient.asNaiveStandardSampler.estimate.get(0))
      }
      
      println("" + nIters + " " + fancyStats.variance + " " + naiveStats.variance)
      
    }
    
    
    
    //probably uses other iters
    //println("Basic estimates")
    //val basicSwapAcceptPr = vpt.pt.swapAcceptPrs.map[mean].toList
    //println(basicSwapAcceptPr)
    
    
    
    println(betas)
    
    
    
    
    
    
    
    
    
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}