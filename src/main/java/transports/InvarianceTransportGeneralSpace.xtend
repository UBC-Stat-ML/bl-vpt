package transports

import org.eclipse.xtend.lib.annotations.Data
import briefj.Indexer

@Data
abstract class InvarianceTransportGeneralSpace<T> extends InvarianceTransportProblem {
  
  val Indexer<T> index
  
  def double logWeight(T s) 
  override double _logWeight(Object s) { logWeight(s as T) }
  
  def double cost(T s1, T s2) 
  override _cost(Object s1, Object s2) {
    cost(s1 as T, s2 as T)
  }
  
  override unpack(int i) {
    index.i2o(i)
  }
  
  override size() {
    index.size
  }
  
}