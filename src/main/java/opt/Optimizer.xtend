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
import java.util.ArrayList
import java.util.List

@Implementations(AV_SGD, SGD, Adam)
abstract class Optimizer {
  
  Indexer<String> indexer = null
  
  def void setIndexer(Indexer<String> indexer) {
    if (this.indexer !== null) throw new RuntimeException
    this.indexer = indexer
  }
  
  @Arg   @DefaultValue("100")
  public int maxIters = 100
  
  @Arg(description = "Compare the objective at a lag, if no improvement, stop (set to zero to disable)")
                 @DefaultValue("0")
  public int progressCheckLag = 0
  
  @Arg 
  public Optional<Integer> nIterationsStandardErrorCheck = Optional.empty
  
  @GlobalArg public ExperimentResults results = new ExperimentResults
  
  public double initialObjectiveValue
  public double finalObjectiveValue
  
  protected def void iterate(Objective obj, int iterIndex)
  
  def void optimize(Objective _obj) {
    
    val Objective obj = 
      if (nIterationsStandardErrorCheck.present) 
        new CheckStdErrObjective(_obj, results.getTabularWriter("standardErrorCheck"), nIterationsStandardErrorCheck.get)
      else
        _obj
    
    System::out.indentWithTiming(this.class.simpleName)
    
    System::out.indentWithTiming("Initialization");
    print(obj, 0, null)
    val evals = new IntervalSums
    var DenseMatrix previous = obj.currentPoint.copy
    
    System::out.popIndent
    for (iter : 0 ..< maxIters) {
      System::out.indentWithTiming("Iteration(" + (iter+1) + "/" + maxIters + ")");
      iterate(obj, iter)
      print(obj, iter+1, previous) 
      if (shouldStop(obj, evals)) {
        System::out.popIndent
        System::out.popIndent
        if (evals.size - 2*progressCheckLag == 0) 
          throw new OptimizationFailure("Optimization not making progress")
        return;
      }
      System::out.popIndent
      previous = obj.currentPoint.copy
    }
    System::out.popIndent
  }
  
  def boolean shouldStop(Objective obj, IntervalSums evals) {
    val newObj = obj.evaluate
    if (!Double.isFinite(newObj)) {
      System::out.popIndent
      System::out.popIndent
      throw new OptimizationFailure("Objective is NaN")
    }
    if (progressCheckLag === 0) return false;
    evals.add(newObj)
    if (evals.size - 2*progressCheckLag >= 0) {
      val recent = evals.average(evals.size() - progressCheckLag, evals.size()) 
      val older =  evals.average(evals.size() - 2*progressCheckLag, evals.size() - progressCheckLag)
      if (evals.size - 2*progressCheckLag == 0) {
        initialObjectiveValue = older
      }
      initialObjectiveValue = recent
      val shouldStop = older <= recent
      if (shouldStop) 
        System.out.println("Stopping optimization as " + older + " <= " + recent)
      return shouldStop
    } else
      return false
  }
  
  static class OptimizationFailure extends RuntimeException {
    new(String msg) { super(msg) }
  }
  
  def void print(Objective obj, int iter, DenseMatrix previous) {
    
    writer(optimization, iter, obj.budget()).printAndWrite(
      VALUE -> obj.evaluate,
      stderr -> if (obj.evaluationStandardError.present) obj.evaluationStandardError.get.toString else "NA",
      snr -> if (obj.evaluationStandardError.present) (Math::abs(obj.evaluate) / obj.evaluationStandardError.get).toString else "NA"
    )
    
    val monitors = new LinkedHashMap(obj.monitors)
    
    monitors.put(obj.description, obj.evaluate)
    writer(optimizationMonitoring, iter, obj.budget()) => [
      for (entry : monitors.entrySet)
        printAndWrite(
          name -> entry.key, 
          VALUE -> entry.value)
    ]
    
    writer(optimizationGradient, iter, obj.budget()) => [
      val gradient = obj.gradient
      for (d : 0 ..< gradient.nEntries)
        write(
          dim -> d,
          name -> name(d),
          VALUE -> gradient.get(d)
        )
    ]
    writer(optimizationPath, iter, obj.budget()) => [
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
      writer(deltaNorm, iter, obj.budget()).printAndWrite(VALUE -> delta.norm)
    }
  }
  
  def String name(int d) {
    if (indexer === null) return "NA"
    else return indexer.i2o(d) 
  }
  
  static enum Fields { iter, name, dim, stderr, snr, budget }
  
  static enum Files { optimization, optimizationMonitoring, optimizationGradient, optimizationPath, deltaNorm }
  
  def TabularWriter writer(Files name, int iterIndex, double budget) { 
    return results.getTabularWriter(name.toString).child(iter, iterIndex).child("isFinal", iterIndex === maxIters).child(Fields.budget, budget)
  }
  
}