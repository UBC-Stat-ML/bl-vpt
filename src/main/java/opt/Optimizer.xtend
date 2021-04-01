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
import blang.inits.experiments.tabwriters.TabularWriter

@Implementations(AV_SGD, Careful_SGD)
abstract class Optimizer {
  
  @Arg   @DefaultValue("100")
  public int maxIters = 100
  
  @GlobalArg public ExperimentResults results = new ExperimentResults
  
  def void iterate(Objective obj, int iter)
  
  def void optimize(Objective obj) {
    System::out.indentWithTiming(this.class.simpleName)
    for (iter : 0 ..< maxIters) {
      print(obj, iter)
      iterate(obj, iter)
    }
    print(obj, maxIters)
    System::out.popIndent
  }
  
  def void print(Objective obj, int iter) {
    writer("optimization", iter).printAndWrite(
      "objective" -> obj.evaluate
    )
    writer("optimization-estimators", iter) => [
      write(
        "dim" -> -1, 
        "value" -> obj.evaluate
      )
      val gradient = obj.gradient
      for (d : 0 ..< gradient.nEntries)
        write(
          "dim" -> d,
          "value" -> gradient.get(d)
        )
    ]
    writer("optimization-path", iter) => [
      val point = obj.currentPoint
      for (d : 0 ..< point.nEntries)
        write(
          "dim" -> d,
          "value" -> point.get(d)
        )
    ]
  }
  
  def TabularWriter writer(String name, int iter) { 
    return results.getTabularWriter(name).child("iter", iter).child("isFinal", iter === maxIters)
  }
  
}