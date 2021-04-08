package ptgrad

import blang.engines.internals.PosteriorInferenceEngine
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.runtime.SampledModel
import blang.inits.Arg
import blang.engines.internals.factories.PT
import xlinear.DenseMatrix
import blang.engines.ParallelTempering
import ptgrad.is.Sample
import java.util.List
import java.util.Map
import java.util.LinkedHashMap
import java.util.ArrayList
import ptgrad.is.FixedSample

import blang.inits.DefaultValue
import ptgrad.TemperingObjective.ObjectiveType
import ptgrad.TemperingObjective.Rejection
import opt.Optimizer
import blang.inits.GlobalArg
import blang.inits.experiments.ExperimentResults
import java.util.Optional
import opt.AV_SGD
import opt.SGD

class VariationalPT implements PosteriorInferenceEngine {
  
  @Arg 
  public val PT pt = new PT
  
  @Arg       @DefaultValue("true")
  public boolean optimize = true
  
  @Arg                @DefaultValue("0.25")
  public double miniBurnInFraction = 0.25
  
  @Arg            @DefaultValue("20")
  public int nScansPerGradient = 20
    
  @Arg                  @DefaultValue("Rejection")
  public ObjectiveType objective = new Rejection
  
  @Arg              @DefaultValue("SGD")
  public Optimizer optimizer = new SGD 
  
  @Arg                 @DefaultValue("IS")
  public Antithetics antithetics = Antithetics.IS
  
  static enum Antithetics { OFF, IS, MCMC }
  
  @Arg  @DefaultValue("1.0")
  public double relativeESSNeighbourhoodThreshold = 1.0
  
  @GlobalArg public ExperimentResults results = new ExperimentResults
  
  @Arg
  public Optional<List<Double>> initialParameters = Optional.empty
  
  public var DenseMatrix parameters = null
  
  override check(GraphAnalysis analysis) {
    pt.check(analysis)
  }
  
  override performInference() {
    pt.performInference
    if (optimize) {
      val objective = new TemperingObjective(this)  
      optimizer.optimize(objective)
    }
  }
  
  def betas() {
    return (0 ..< pt.nChains).map[pt.states.get(it).exponent].toList
  }
  
  def Map<Double, List<Sample>> initSampleLists() {
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
      val currentBetas = if (antithetics == Antithetics.IS && relativeESSNeighbourhoodThreshold != 1.0) 
        betas() 
      else 
        new ArrayList<Double> => [
        add(allBetas.get(i))
        if (i - 1 >= 0) 
          add(allBetas.get(i - 1))
        if (i + 1 < allBetas.size)
          add(allBetas.get(i + 1))
      ]
      val sample = new FixedSample(interpolation, currentBetas, beta)
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
    if (initialParameters.present) {
      val inits = initialParameters.get
      if (inits.size !== this.parameters.nEntries) 
        throw new RuntimeException
      for (i : 0 ..< this.parameters.nEntries) 
        this.parameters.set(i, inits.get(i))
    }
  }
  
  def Interpolation model(int chainIndex) {
    (pt.states.get(chainIndex).model as Variational).interpolation
  }
  
}