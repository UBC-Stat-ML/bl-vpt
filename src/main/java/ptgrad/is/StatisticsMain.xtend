package ptgrad.is

import blang.inits.experiments.Experiment
import blang.runtime.Runner
import ptgrad.ConjugateNormal
import ptgrad.Variational
import ptgrad.VariationalPT
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import is.DiagonalHalfSpaceImportanceSampler
import bayonet.math.NumericalUtils

class StatisticsMain extends Experiment {
  
  override run() {
    val runner = Runner::create(results.resultsFolder,
      "--model", Variational.canonicalName, 
      "--model.interpolation", ConjugateNormal.canonicalName,
      "--engine", "ptgrad.VariationalPT",
      "--engine.pt.nPassesPerScan", "20",
      "--engine.pt.nChains", "8",
      "--engine.optimize", "false"
    )
    runner.run()
    val vpt = runner.engine as VariationalPT
    
    // next check: rejection rates correctly estimated
    val betas = vpt.betas
    val beta1 = betas.get(0)
    val beta2 = betas.get(1)
    for (nIters : (1 .. 3).map[Math::pow(10, it) as int]) {
      val fancyStats = new SummaryStatistics
      val naiveStats = new SummaryStatistics
      
      val fancyVarEst = new SummaryStatistics
      val naiveVarEst = new SummaryStatistics
      
      val fancySingleVarEst = new SummaryStatistics
      
      val acceptStats = new SummaryStatistics
      val acceptStatst1 = new SummaryStatistics
      val acceptStatst2 = new SummaryStatistics
      
      for (mc : 0 ..< 100) {
        val samples = vpt.iterate(nIters)
        val samples1 = samples.get(beta1)
        val samples2 = samples.get(beta2)
        
        val expectedUntruncatedRatio = TemperingExpectations::expectedUntruncatedRatio(new ChainPair(#[beta1, beta2], #[samples1, samples2]))
        val probabilityOfTruncation = TemperingExpectations::probabilityOfTruncation(new ChainPair(#[beta1, beta2], #[samples1, samples2]))
        
        check(expectedUntruncatedRatio)
        check(probabilityOfTruncation)
        
        val expectedAccept = expectedUntruncatedRatio.estimate + probabilityOfTruncation.estimate
        acceptStats.addValue(expectedAccept.get(0))
        acceptStatst1.addValue(expectedUntruncatedRatio.estimate.get(0))
        acceptStatst2.addValue(probabilityOfTruncation.estimate.get(0))

        val expectedGradient = TemperingExpectations::expectedTruncatedGradient(new ChainPair(#[beta1, beta2], #[samples1, samples2]), 0)
        
        check(expectedGradient)
        
        fancyStats.addValue(expectedGradient.estimate.get(0))
        fancySingleVarEst.addValue(expectedGradient.varianceEstimate.get(0))
        var stdErr = expectedGradient.standardError.get(0)
        fancyVarEst.addValue(stdErr*stdErr)
    
        //val naive = expectedUntruncatedRatio.asNaiveStandardSampler.estimate + probabilityOfTruncation.asNaiveStandardSampler.estimate
        naiveStats.addValue(expectedGradient.asNaiveStandardSampler.estimate.get(0))
        stdErr = expectedGradient.asNaiveStandardSampler.standardError.get(0)
        naiveVarEst.addValue(stdErr*stdErr)
      }
      
      println("" + nIters + " f-var=" + fancyStats.variance + " n-var=" + naiveStats.variance + " "
          + "f-estvar=" + fancyVarEst.mean + " n-estvar=" + naiveVarEst.mean + " "
          + " f-est=" + fancyStats.mean + " n-est=" + naiveStats.mean + " f-var-single-estimate=" + fancySingleVarEst.mean
      )
      
      println("->" + acceptStats.mean)
      println("->" + acceptStatst1.mean)
      println("->" + acceptStatst2.mean)
      
    }
    
    //probably uses other iters
    //println("Basic estimates")
    //val basicSwapAcceptPr = vpt.pt.swapAcceptPrs.map[mean].toList
    //println(basicSwapAcceptPr)
    
    
    
    println(betas)

  }
  
  def static void check(DiagonalHalfSpaceImportanceSampler<?,?> s) {
    
    val fw = s.weightedSum(1, 1).get(0)
    val nw = s.asCosltyStandardSampler.weightedSum(1, 1).get(0)
    
    if (!NumericalUtils::isClose(fw, nw, 1e-6)) {
      s.weightedSum(1, 1)
      s.asCosltyStandardSampler.weightedSum(1, 1).get(0)
      System.err.println("brok")
    }
    
    
    val fancy = s.estimate.get(0)
    val coslty = s.asCosltyStandardSampler.estimate.get(0)
    NumericalUtils::checkIsClose(fancy, coslty)
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}