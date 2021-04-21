package opt

import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Delegate
import org.eclipse.xtend.lib.annotations.Data
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import blang.inits.experiments.tabwriters.TabularWriter

@Data
class CheckStdErrObjective implements Objective {
  
  @Delegate
  val Objective objective
  
  val TabularWriter writer
  
  val int nSamples
  
  override moveTo(DenseMatrix point) {
    objective.moveTo(point)
    val estimate = objective.evaluationStandardError
    if (!estimate.present) return
    
    val summaryStat = new SummaryStatistics
    for (i : 0 ..< nSamples) {
      objective.moveTo(point)
      summaryStat.addValue(objective.evaluate)
    }
    
    writer.printAndWrite(
      "monteCarlo" -> summaryStat.standardDeviation,
      "estimate" -> estimate.get
    )
  }
  
}