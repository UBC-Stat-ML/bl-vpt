package ptgrad

import blang.engines.internals.PosteriorInferenceEngine
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.runtime.SampledModel
import blang.inits.Arg
import blang.engines.internals.factories.PT
import xlinear.DenseMatrix
import blang.engines.ParallelTempering
import xlinear.AutoDiff
import java.util.HashMap
import ptgrad.is.Sample
import java.util.List
import java.util.Map
import java.util.LinkedHashMap
import java.util.ArrayList
import ptgrad.is.FixedSample

import static java.lang.Math.*
import opt.SGD
import blang.inits.DefaultValue
import ptgrad.TemperingObjective.ObjectiveType
import ptgrad.TemperingObjective.Rejection
import briefj.BriefLog

class VariationalPT implements PosteriorInferenceEngine {
  
  @Arg 
  public val PT pt = new PT
  
  @Arg       @DefaultValue("true")
  public boolean optimize = true
  
  @Arg                @DefaultValue("0.5")
  public double miniBurnInFraction = 0.5
  
  @Arg            @DefaultValue("100")
  public int nScansPerGradient = 100
    
  @Arg                  @DefaultValue("Rejection")
  public ObjectiveType objective = new Rejection
  
  public var DenseMatrix parameters = null
  
  override check(GraphAnalysis analysis) {
    pt.check(analysis)
  }
  
  override performInference() {
    // start with an adaptive pass to learn good starting schedule
    pt.performInference
    
    System.out.println("Something weird...")
    BriefLog::warnOnce("remove!") 
    parameters.set(0, 1.5) 
    if (optimize) {
      val objective = new TemperingObjective(this)  
      val sgd = new SGD(objective)
      sgd.optimize
    }
    
//    // quick check
//    for (var double phi = -3; phi < 3; phi += 0.1) {
//      parameters.set(0, phi)
//      iterate(1000)
//      println("" + phi + "\t" + inefficiency + " " + "\t" + sumRejections)
//    }
  }
  
  def betas() {
    return (0 ..< pt.nChains).map[pt.states.get(it).exponent].toList
  }
  
  def initSampleLists() {
    val samples = new LinkedHashMap<Double, List<Sample>>
    for (i : 0 ..< pt.nChains) {
      val beta = pt.states.get(i).exponent
      samples.put(beta, new ArrayList<Sample>)
    }
    return samples
  }
  
  def void record(Map<Double, List<Sample>> samples) {
    val allBetas = betas()
    for (i : 0 ..< pt.nChains) {
      val beta = pt.states.get(i).exponent
      val interpolation = model(i)
      val currentBetas = new ArrayList<Double> => [
        add(allBetas.get(i))
        if (i - 1 >= 0) 
          add(allBetas.get(i - 1))
        if (i + 1 < allBetas.size)
          add(allBetas.get(i + 1))
      ]
      val sample = new FixedSample(interpolation, currentBetas)
      samples.get(beta).add(sample)
    }
  }
  
  def Map<Double, List<Sample>> iterate(int nScans) {
    var Map<Double, List<Sample>> samples = initSampleLists()
    val it = pt
    swapAcceptPrs = ParallelTempering::initStats(nChains)
    initSampleLists()
    for (i : 0 ..< nScans) {
      moveKernel(nPassesPerScan)
      swapKernel
      samples.record
    }
    return samples
  }
  
  def double inefficiency() {
    objective[s|(1.0-s)/s]
  }
  
  def double sumRejections() {
    objective[s|1.0-s]
  }
  
  def double objective((Double)=>Double acceptToTerm) {
    pt.swapAcceptPrs.map[mean as double].filter[!Double.isNaN(it)].map(acceptToTerm).reduce[a,b|a+b]
  }
  
  override setSampledModel(SampledModel model) {
    pt.sampledModel = model
    // need to create a shared variational parameter
    this.parameters = model(0).parameters
    for (chain : 0 ..< pt.nChains)
      model(chain).parameters = this.parameters
  }
  
  def Interpolation model(int chainIndex) {
    (pt.states.get(chainIndex).model as Variational).interpolation
  }
  
}