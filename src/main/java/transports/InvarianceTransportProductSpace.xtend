package transports

import org.eclipse.xtend.lib.annotations.Data
import bayonet.math.CoordinatePacker

@Data
abstract class InvarianceTransportProductSpace extends InvarianceTransportProblem {
  
  val CoordinatePacker index
  
  def double logWeight(int [] s) 
  override double _logWeight(Object s) { logWeight(s as int[]) }
  
  def double cost(int [] s1, int [] s2) 
  override _cost(Object s1, Object s2) {
    cost(s1 as int[], s2 as int [])
  }
  
  override unpack(int i) {
    index.int2coord(i)
  }
  
  override size() {
    index.size
  }
  
}