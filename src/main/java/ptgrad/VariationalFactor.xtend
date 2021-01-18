package ptgrad

import org.apache.commons.math3.analysis.differentiation.DerivativeStructure
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import briefj.Indexer
import xlinear.AutoDiff.Differentiable

// one factor of the form W(phi, x_i, beta) 
// these will get pulled by object graph analysis of ONE model
// NB: keep in mind need to avoid lambda expression in the object graph!
@Data
abstract class VariationalFactor implements Differentiable {
  
  val Indexer<VariationalParameterComponent> components
  
  override DerivativeStructure apply(List<DerivativeStructure> it)
  
  def DerivativeStructure get(List<DerivativeStructure> it, VariationalParameterComponent component) {
    it.get(components.o2i(component))
  }
  
  
  @Data
  static class VariationalParameterComponent {
    val String identifier
  }
}