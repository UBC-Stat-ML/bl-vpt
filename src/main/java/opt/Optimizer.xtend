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
import  static blang.inits.experiments.tabwriters.TidySerializer.VALUE
import briefj.Indexer

@Implementations(AV_SGD, SGD, Adam)
abstract class Optimizer {
  
  Indexer<String> indexer = null
  
  def void setIndexer(Indexer<String> indexer) {
    if (this.indexer !== null) throw new RuntimeException
    this.indexer = indexer
  }
  
  @Arg   @DefaultValue("100")
  public int maxIters = 100
  
  @GlobalArg public ExperimentResults results = new ExperimentResults
  
  def void iterate(Objective obj, int iter)
  
  def void optimize(Objective obj) {
    System::out.indentWithTiming(this.class.simpleName)
    for (iter : 0 ..< maxIters) {
      System::out.indentWithTiming("Iteration(" + (iter+1) + "/" + maxIters + ")");
      print(obj, iter)
      iterate(obj, iter)
      System::out.popIndent
    }
    print(obj, maxIters)
    System::out.popIndent
  }
  
  def void print(Objective obj, int iter) {
    writer("optimization", iter).printAndWrite(
      VALUE -> obj.evaluate
    )
    writer("optimization-estimators", iter) => [
      write(
        "dim" -> -1, 
        NAME -> "objective",
        VALUE -> obj.evaluate
      )
      val gradient = obj.gradient
      for (d : 0 ..< gradient.nEntries)
        write(
          "dim" -> d,
          NAME -> name(d),
          VALUE -> gradient.get(d)
        )
    ]
    writer("optimization-path", iter) => [
      val point = obj.currentPoint
      for (d : 0 ..< point.nEntries)
        write(
          "dim" -> d,
          NAME -> name(d),
          "value" -> point.get(d)
        )
    ]
  }
  
  def String name(int d) {
    if (indexer === null) return "NA"
    else return indexer.i2o(d) 
  }
  
  public static final String ITER = "iter"
  public static final String NAME = "name"
  
  def TabularWriter writer(String name, int iter) { 
    return results.getTabularWriter(name).child(ITER, iter).child("isFinal", iter === maxIters)
  }
  
}