package opt

import blang.inits.Arg
import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Accessors
import blang.inits.GlobalArg
import blang.inits.experiments.ExperimentResults
import blang.System;
import blang.engines.internals.factories.PT.MonitoringOutput
import blang.engines.internals.factories.PT.Column

import static opt.Optimizer.Files.*
import static opt.Optimizer.Fields.*

import static extension xlinear.MatrixExtensions.*
import blang.inits.Implementations
import blang.inits.DefaultValue
import blang.inits.experiments.tabwriters.TabularWriter
import  static blang.inits.experiments.tabwriters.TidySerializer.VALUE
import briefj.Indexer
import java.util.LinkedHashMap
import java.util.Optional
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

@Implementations(AV_SGD, SGD, Adam)
abstract class Optimizer {
  
  Indexer<String> indexer = null
  
  def void setIndexer(Indexer<String> indexer) {
    if (this.indexer !== null) throw new RuntimeException
    this.indexer = indexer
  }
  
  @Arg   @DefaultValue("100")
  public int maxIters = 100
  
  @Arg 
  public Optional<Integer> nIterationsStandardErrorCheck = Optional.empty
  
  @GlobalArg public ExperimentResults results = new ExperimentResults
  
  def void iterate(Objective obj, int iter)
  
  def void optimize(Objective _obj) {
    
    val Objective obj = 
      if (nIterationsStandardErrorCheck.present) 
        new CheckStdErrObjective(_obj, results.getTabularWriter("standardErrorCheck"), nIterationsStandardErrorCheck.get)
      else
        _obj
    
    System::out.indentWithTiming(this.class.simpleName)
    
    System::out.indentWithTiming("Initialization");
    print(obj, 0, null)
    var DenseMatrix previous = obj.currentPoint.copy
    var Double previousObj = null
    val martingaleStatistics = new SummaryStatistics
    System::out.popIndent
    for (iter : 0 ..< maxIters) {
      System::out.indentWithTiming("Iteration(" + (iter+1) + "/" + maxIters + ")");
      iterate(obj, iter)
      print(obj, iter+1, previous) 
      checkProgress(martingaleStatistics, obj, previousObj)
      System::out.popIndent
      previous = obj.currentPoint.copy
      previousObj = obj.evaluate
    }
    System::out.popIndent
  }
  
  def void checkProgress(SummaryStatistics martingaleStatistics, Objective obj, Double previousObj) {
    val newObj = obj.evaluate
    if (!Double.isFinite(newObj)) throw new OptimizationStopped("Objective is NaN")
    if (previousObj === null) return
    val improvement = previousObj - newObj
    martingaleStatistics.addValue(improvement)
    val point = martingaleStatistics.mean
    val radius = 1.96 * martingaleStatistics.standardDeviation / Math::sqrt(martingaleStatistics.n)
    val left = point - radius
    val right = point + radius
    System::out.println("improvement95CI=[" + left + ", " + right + "]")
  }
  
  static class OptimizationStopped extends RuntimeException {
    new(String msg) { super(msg) }
  }
  
  def void print(Objective obj, int iter, DenseMatrix previous) {
    
    writer(optimization, iter).printAndWrite(
      VALUE -> obj.evaluate,
      stderr -> if (obj.evaluationStandardError.present) obj.evaluationStandardError.get.toString else "NA",
      snr -> if (obj.evaluationStandardError.present) (Math::abs(obj.evaluate) / obj.evaluationStandardError.get).toString else "NA"
    )
    
    val monitors = new LinkedHashMap(obj.monitors)
    
    monitors.put(obj.description, obj.evaluate)
    writer(optimizationMonitoring, iter) => [
      for (entry : monitors.entrySet)
        printAndWrite(
          name -> entry.key, 
          VALUE -> entry.value)
    ]
    
    writer(optimizationGradient, iter) => [
      val gradient = obj.gradient
      for (d : 0 ..< gradient.nEntries)
        write(
          dim -> d,
          name -> name(d),
          VALUE -> gradient.get(d)
        )
    ]
    writer(optimizationPath, iter) => [
      val point = obj.currentPoint
      for (d : 0 ..< point.nEntries)
        write(
          dim -> d,
          name -> name(d),
          VALUE -> point.get(d)
        )
    ]
    
    if (previous !== null) {
      val delta = obj.currentPoint - previous
      writer(deltaNorm, iter).printAndWrite(VALUE -> delta.norm)
    }
  }
  
  def String name(int d) {
    if (indexer === null) return "NA"
    else return indexer.i2o(d) 
  }
  
  static enum Fields { iter, name, dim, stderr, snr }
  
  static enum Files { optimization, optimizationMonitoring, optimizationGradient, optimizationPath, deltaNorm }
  
  def TabularWriter writer(Files name, int iterIndex) { 
    return results.getTabularWriter(name.toString).child(iter, iterIndex).child("isFinal", iterIndex === maxIters)
  }
  
}