package xdiff

import org.eclipse.xtend.lib.annotations.Data
import java.util.List
import java.util.ArrayList
//import org.openjdk.jmh.annotations.Benchmark
import com.google.common.base.Stopwatch
import java.util.concurrent.TimeUnit
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import java.util.Random

class XD {
  
  
  
  static val bh = new ArrayList<Object>
  
  def static void main(String [] args) {
    val int dataSize = 100000
    val rand = new Random(1)
    val data = (0 ..< dataSize).map[rand.nextDouble].toList
    
    val dag = new DAG
    val m = dag.variable(2.0)
    val v = test(dataSize, m)
    //println(dag.output.value)
    benchmark(1000) [
      for (n : dag.variables)
        n.op.compute
    ] 
    benchmark(1000) [
      val x = test(dataSize, 2.0, data)
      bh.add(x)
    ]
    benchmark(1000) [
      val x = test2(dataSize, m, data)
      bh.add(x)
    ]
    benchmark(1000) [
      val x = test3(dataSize, 2.0, data)
      bh.add(x)
    ]
    println(bh.last)
  }
  
  /*
   * Too slow!
   * 
   * 28.362725450901817ms +/- 0.1858100499819829
   * 0.01603206412825652ms +/- 0.011031297418639634
   * 2.1683366733466922ms +/- 0.040069571642967455
   * 
   * TODO: cf Julia, python
   * 
   * 100 x hit from double to RealVar/Double
   * 
   * 
   */
  
  def static void benchmark(int nReps, Runnable r) {
    val stats = new SummaryStatistics
    for (i : 0 ..< nReps) {
      val t = Stopwatch.createStarted
      r.run
      t.stop
      if (i > 0.5 * nReps)
        stats.addValue(t.elapsed(TimeUnit.MICROSECONDS))
    }
    println(stats.mean + "us +/- " + 1.96 * stats.standardDeviation/Math::sqrt(stats.n) )
  }

  
  def static RealVar logPoi(int realization, RealVar mean) {
    realization * log(mean) + mean * (-1.0)
  }
  
  def static RealVar test(int size, RealVar m) {
    
    val RealVar p0 = exp(logPoi(0, m))
    val RealVar logRenorm = log(1 + p0)
    var RealVar result = 1.0 * (logPoi(2, m) + logRenorm * (-1.0))
    for (i : 0 ..< size) {
      result = result + 1.0 * (logPoi(2, m) + logRenorm * (-1.0))
    }
    return result
  }
  
  def static double logPoi(double realization, double mean) {
    realization * Math::log(mean) + mean * (-1.0)
  }
  
  def static double test(int size, double m, List<Double> data) {
    
    val double p0 = Math::exp(logPoi(0, m))  
    val double logRenorm = Math::log(1 + p0)
    var double result = 1.0 * (logPoi(2, m) + logRenorm * (-1.0))
    for (i : 0 ..< size) {
      result = result + data.get(i) * (logPoi(data.get(i), m) + logRenorm * (-1.0))
    }
    return result
  }
  
  def static double logPoi2(double realization, RealVar mean) {
    realization * Math::log(mean.value) + mean.value * (-1.0)
  }
  
  def static double test2(int size, RealVar m, List<Double> data) {
    
    val double p0 = Math::exp(logPoi2(0, m))  
    val double logRenorm = Math::log(1 + p0)
    var double result = 1.0 * (logPoi2(2, m) + logRenorm * (-1.0))
    for (i : 0 ..< size) {
      result = result + data.get(i) * (logPoi2(data.get(i), m) + logRenorm * (-1.0))
    }
    return result
  }
  
    def static double logPoi3(double realization, Double mean) {
    realization * Math::log(mean.doubleValue) + mean.doubleValue * (-1.0)
  }
  
  def static double test3(int size, Double m /* if change to double, 100x faster! */, List<Double> data) {
    
    val double p0 = Math::exp(logPoi3(0, m))  
    val double logRenorm = Math::log(1 + p0)
    var double result = 1.0 * (logPoi3(2, m) + logRenorm * (-1.0))
    for (i : 0 ..< size) {
      result = result + data.get(i) * (logPoi3(data.get(i), m) + logRenorm * (-1.0))
    }
    return result
  }
  
  static class DAG {
    val List<Variable<?>> variables = new ArrayList
    
    def Variable<?> output() {
      variables.last
    }
    
    def RealVar variable(double value) {
      return new RealVar(this, new LeafOp(value))
    }
    
    def void computeGradient() {
      val last = output as RealVar
      last.derivative = 1.0
      for (output : variables.reverseView.filter(RealVar)) {
        val op = output.op
        if (op instanceof Differentiable) {
          val inputs = op.inputs
          for (i : 0 ..< inputs.size) {
            val input = inputs.get(i)
            if (input instanceof RealVar) {
              val opDerivative = op.derivative(i)
              input.derivative += output.derivative * opDerivative
            }
          }
        }
      }
    }
  }
  
  static class Variable<T> { 
    val DAG dag
    public val Op<T> op
    public val T value
    
    new (DAG dag, Op<T> op) {
      this.dag = dag
      this.op = op
      this.value = op.compute
      dag.variables.add(this)
    }
  }
  
  static class RealVar extends Variable<Double> {
    var double derivative = 0.0 // of this variable w.r.t DAG output
    new(DAG dag, Op<Double> op) { super(dag, op) }
  }
  
  @Data
  static class LeafOp<T>implements Op<T> {
    val T value
    override inputs() { #[] }
    override compute() { value }
  }
  
  static interface Op<T> {
    def List<Variable<?>> inputs()
    def T compute() // later, could allow also recompute(T inPlace)
  }
  
  static interface Differentiable {
    def double derivative(int inputIndex)
  }
  
  static abstract class BinaryOp<T> implements Op<T> {
    public val List<Variable<T>> inputs
    override List<Variable<?>> inputs() { inputs as List }
    new (Variable<T> v1, Variable<T> v2) {
      inputs = #[v1, v2]
    }
    def Variable<T> x() { inputs.get(0) }
    def Variable<T> y() { inputs.get(1) }
  }
  
  static abstract class UnaryOp<T> implements Op<T> {
    public val List<Variable<T>> inputs
    override List<Variable<?>> inputs() { inputs as List }
    new (Variable<T> v1) {
      inputs = #[v1]
    }
    def Variable<T> x() { inputs.get(0) }
  }
  
  static class Product extends BinaryOp<Double> implements Differentiable {
    new(RealVar v1, RealVar v2) {
      super(v1, v2)
    }
    override compute() { x.value * y.value }
    override double derivative(int inputIndex) {
      val other = inputs.get(1 - inputIndex)
      return other.value
    }
  }
  
  static class Scale extends UnaryOp<Double> implements Differentiable {
    val double c
    new(RealVar v1, Number c) {
      super(v1)
      this.c = c.doubleValue
    }
    override compute() { x.value * c }
    override double derivative(int inputIndex) {
      return c
    }
  }
  
  static class Ln extends UnaryOp<Double> implements Differentiable {
    new(RealVar v1) {
      super(v1)
    }
    override compute() { Math::log(x.value) }
    override double derivative(int inputIndex) {
      return 1.0 / x.value
    }
  }
  
  static class Exp extends UnaryOp<Double> implements Differentiable {
    new(RealVar v1) {
      super(v1)
    }
    override compute() { Math::exp(x.value) }
    override double derivative(int inputIndex) { Math::exp(x.value) }
  }
  
  static class Sum extends BinaryOp<Double> implements Differentiable {
    new(RealVar v1, RealVar v2) { super(v1, v2) }
    override compute() { x.value + y.value }
    override double derivative(int inputIndex) { 1 }
  }
  
  static class Add extends UnaryOp<Double> implements Differentiable {
    val double c
    new(RealVar v1, Number c) {
      super(v1)
      this.c = c.doubleValue
    }
    override compute() { x.value + c }
    override double derivative(int inputIndex) { 1 }
  }
  
  def static RealVar *(RealVar x0, RealVar x1) {
    val dag = dag(x0, x1)
    return new RealVar(dag, new Product(x0, x1))
  }
  
  def static RealVar *(RealVar x0, Number n) {
    val dag = dag(x0)
    return new RealVar(dag, new Scale(x0, n))
  }
  
  def static RealVar *(Number n, RealVar x0) {
    return x0 * n
  }
  
  def static RealVar +(RealVar x0, RealVar x1) {
    val dag = dag(x0, x1)
    return new RealVar(dag, new Sum(x0, x1))
  }
  
  def static RealVar +(RealVar x0, Number n) {
    val dag = dag(x0)
    return new RealVar(dag, new Add(x0, n))
  }
  
  def static RealVar +(Number n, RealVar x0) {
    return x0 + n
  }
  
  def static RealVar log(RealVar x) {
    val dag = dag(x)
    return new RealVar(dag, new Ln(x))
  }
  
  def static RealVar exp(RealVar x) {
    val dag = dag(x)
    return new RealVar(dag, new Exp(x))
  }
  
  def static DAG dag(Variable<?> ... vars) {
    // TODO: check they all defined on same context
    vars.get(0).dag
  }
  
  
}