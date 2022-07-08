package iscm

import java.io.File
import briefj.BriefIO
import java.util.ArrayList
import blang.engines.internals.Spline
import com.google.common.primitives.Doubles
import blang.engines.internals.Spline.MonotoneCubicSpline
import blang.engines.internals.EngineStaticUtils
import blang.inits.experiments.ExperimentResults

class DebugSpikeSlab {
  def static void main(String [] args) {
    val lambdaFile = new File("/Users/bouchard/experiments/iscm-nextflow/deliverables/ISCM+PT/aggregated/lambdaInstantaneous.csv")
    
    val iter = BriefIO::readLines(lambdaFile)
      .indexCSV
      .filter[get("model") == "glms.SpikeSlabClassification$Builder"]
      .filter[get("round") == "2"]
      .filter[get("method") == "iscm.ISCM"]
      
    
    val annealingParams = new ArrayList<Double> => [ add(0.0) ]
    val cumulative = new ArrayList<Double>      => [ add(0.0) ]
    for (it : iter) {
      annealingParams.add(Double::parseDouble(get("beta")))
      cumulative.add(cumulative.last + 0.01 * Double::parseDouble(get("value")))
    }
    
    val xs = Doubles::toArray(annealingParams)
    val ys = Doubles::toArray(cumulative)
    val spline = Spline::createMonotoneCubicSpline(xs, ys) as MonotoneCubicSpline
    
    
    val nSMCItersForNextRound = 595
    val updated = EngineStaticUtils::fixedSizeOptimalPartition(spline, nSMCItersForNextRound)
    
    
    val result = new ExperimentResults
    
    for (var int i = 0; i < updated.size; i++)
      result.getTabularWriter("schedule-" + nSMCItersForNextRound)
        .write(
          "index" -> i,
          "value" -> updated.get(i)
        )
    
    
    result.closeAll
  }
}