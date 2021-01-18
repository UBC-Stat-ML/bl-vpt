package ptgrad

import blang.engines.internals.PosteriorInferenceEngine
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.runtime.SampledModel
import blang.inits.Arg
import blang.engines.internals.factories.PT

class VariationalPT implements PosteriorInferenceEngine {
  
  @Arg 
  val PT pt = new PT
  
  override check(GraphAnalysis analysis) {
    pt.check(analysis)
  }
  
  override performInference() {
    throw new UnsupportedOperationException("TODO: auto-generated method stub")
  }
  
  override setSampledModel(SampledModel model) {
    pt.sampledModel = model
    // need to create a shared variational parameter!
    // TODO
  }
  
  def model(int i) {
    //pt.states.get(i).model as 
  }
  
}