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
import blang.inits.Arg
import ptgrad.TemperingObjective.SKL
import ptgrad.TemperingObjective.Rejection
import blang.inits.DefaultValue
import java.util.LinkedHashMap
import briefj.BriefMaps
import ptgrad.TemperingObjective.Inef
import ptgrad.TemperingObjective.SqrtHalfSKL
import ptgrad.TemperingObjective.RejectionCV
import ptgrad.TemperingObjective.CVTest

class ToyNormalTest extends Experiment {
  
  @Arg @DefaultValue("0.0")
  double paramStart = 0.0
  
  @Arg     @DefaultValue("0.2")
  double paramIncrement = 0.2
  
  @Arg @DefaultValue("2.0")
  double   paramEnd = 2.0
  
  @Arg              @DefaultValue("ptgrad.ToyNormal")
  String interpolationClassName = "ptgrad.ToyNormal"
  
  @Arg @DefaultValue("1000")
  int      nOuterMC = 1000
  
  @Arg @DefaultValue("100")
  int      nInnerMC = 100
  
  val static objectiveKey = "objective"
  def static gradientKey(int i) { "gradient_" + i }
  
  override run() {
    val runner = Runner::create(results.resultsFolder,
      "--model", Variational.canonicalName, 
      "--model.interpolation", interpolationClassName,
      "--engine", "ptgrad.VariationalPT",
      "--engine.pt.nPassesPerScan", "3",
      "--engine.pt.nChains", "2",
      "--engine.nScansPerGradient", "" + nInnerMC,
      "--engine.optimize", "false"
    )
    val vpt = runner.engine as VariationalPT
    
    runner.run()
    
    for (var double param = paramStart; param < paramEnd; param += paramIncrement) 
      for (type : #[new CVTest]) {
        vpt.objective = type
      
        vpt.parameters.set(0, param)
        val objective = new TemperingObjective(vpt)  
        val stats = new LinkedHashMap<String,SummaryStatistics>
        for (i : 0 ..< nOuterMC) {
          val valueGradientPair = objective.estimate
          BriefMaps::getOrPut(stats, objectiveKey, new SummaryStatistics).addValue(valueGradientPair.key)
          val gradient = valueGradientPair.value
          for (c : 0 ..< gradient.nEntries)
            BriefMaps::getOrPut(stats, gradientKey(c), new SummaryStatistics).addValue(gradient.get(c))
        }
        for (entry : stats.entrySet) {
          results.getTabularWriter("snrs").printAndWrite(
            "parameter" -> param,
            "type" -> type.class.simpleName,
            "coord" -> entry.key,
            "mean" -> entry.value.mean,
            "SD" -> entry.value.standardDeviation,
            "SNR" -> Math::abs(entry.value.mean/entry.value.standardDeviation)
          )
        }
    }
    
//    val objective = new TemperingObjective(vpt)  
//    println("obj " + objective.evaluate + " " + PTGradientTest::analyticRejectRate(delta))
//    
//    println("grad " + objective.gradient.get(0) + " " + PTGradientTest::analyticRejectGradient(delta))
    

  }
  

  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}