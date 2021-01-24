package ptgrad

import blang.engines.internals.PosteriorInferenceEngine
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.runtime.SampledModel
import blang.inits.Arg
import blang.engines.internals.factories.PT
import xlinear.DenseMatrix
import blang.engines.ParallelTempering
import xlinear.AutoDiff

class VariationalPT implements PosteriorInferenceEngine {
  
  @Arg 
  val PT pt = new PT
  
  var DenseMatrix parameters = null
  
  override check(GraphAnalysis analysis) {
    pt.check(analysis)
  }
  
  override performInference() {
    // start with an adaptive pass to learn good starting schedule
    pt.performInference
    
    // quick check
    for (var double phi = -3; phi < 3; phi += 0.1) {
      parameters.set(0, phi)
      iterate(100)
      println("" + phi + "\t" + inefficiency + " ")
    }
  }
  
  def void iterate(int nScans) {
    val it = pt
    swapAcceptPrs = ParallelTempering::initStats(nChains)
    for (i : 0 ..< nScans) {
      moveKernel(nPassesPerScan)
      swapKernel
    }
  }
  
  def double inefficiency() {
    pt.swapAcceptPrs.map[mean as double].filter[!Double.isNaN(it)].map[s|(1.0-s)/s].reduce[a,b|a+b]
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