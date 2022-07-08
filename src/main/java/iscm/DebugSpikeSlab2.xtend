package iscm

import java.io.File
import briefj.BriefIO
import java.util.ArrayList
import blang.engines.internals.Spline
import com.google.common.primitives.Doubles
import blang.engines.internals.Spline.MonotoneCubicSpline
import blang.engines.internals.EngineStaticUtils
import blang.inits.experiments.ExperimentResults

class DebugSpikeSlab2 {
  def static void main(String [] args) {
    val essFile = new File("/Users/bouchard/w/ptanalysis/results/all/2022-07-07-22-19-25-R97EUgtf.exec/monitoring/relativeConditionalESS.csv")
    
    val iter = BriefIO::readLines(essFile)
      .indexCSV
      .filter[get("round") == "13"]
    
    val annealingParams = new ArrayList<Double> 
    val ess = new ArrayList<Double> 
    for (it : iter) {
      annealingParams.add(Double::parseDouble(get("beta")))
      ess.add(Double::parseDouble(get("relativeConditionalESS")))
    }
    annealingParams.add(1.0)
    
    val spline = ISCM::estimateCumulativeLambda(annealingParams, ess)
    
    
    val nSMCItersForNextRound = 20
    val updated = EngineStaticUtils::fixedSizeOptimalPartition(spline, nSMCItersForNextRound)
    
    val result = new ExperimentResults
    
    for (var int i = 0; i < updated.size; i++)
      result.getTabularWriter("schedule-debug")
        .write(
          "index" -> i,
          "value" -> updated.get(i)
        )
    
    
    result.closeAll
  }
}