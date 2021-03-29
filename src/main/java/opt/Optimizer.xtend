package opt

import blang.inits.Arg
import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Accessors
import blang.inits.GlobalArg
import blang.inits.experiments.ExperimentResults
import blang.System;
import blang.engines.internals.factories.PT.MonitoringOutput
import blang.engines.internals.factories.PT.Column

import static extension xlinear.MatrixExtensions.*
import blang.inits.Implementations
import blang.inits.DefaultValue

@Implementations(AV_SGD, Careful_SGD)
abstract class Optimizer {
  
  @Arg   @DefaultValue("100")
  public int maxIters = 100
  
  @GlobalArg public ExperimentResults results = new ExperimentResults
  
  def void iterate(Objective obj, int iter)
  
  def void optimize(Objective obj) {
    System::out.indentWithTiming(this.class.simpleName)
    for (iter : 0 ..< maxIters) {
      results.getTabularWriter("optimization").printAndWrite(
        "iter" -> iter,
        "point" -> obj.currentPoint.vectorToArray.join(" "), 
        "objective" -> obj.evaluate,
        "gradient" -> obj.gradient.vectorToArray.join(" ")
      )
      iterate(obj, iter)
    }
    System::out.popIndent
  }
  
}