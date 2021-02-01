package opt

import blang.inits.Arg
import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Accessors
import blang.inits.GlobalArg
import blang.inits.experiments.ExperimentResults
import blang.System;
import blang.engines.internals.factories.PT.MonitoringOutput
import blang.engines.internals.factories.PT.Column

abstract class Optimizer {
  
  public val Objective obj
  
  @Arg
  public int maxIters = 100
  
  @GlobalArg public ExperimentResults results = new ExperimentResults
  
  new (Objective obj) { this.obj = obj }
  
  def DenseMatrix iterate(int iter)
  
  def void optimize() {
    System::out.indentWithTiming(this.class.simpleName)
    for (iter : 0 ..< maxIters) {
      results.getTabularWriter("optimization").printAndWrite(
        "iter" -> iter,
        "objective" -> obj.evaluate
      )
      obj.moveTo(iterate(iter))
    }
    System::out.popIndent
  }
  
}