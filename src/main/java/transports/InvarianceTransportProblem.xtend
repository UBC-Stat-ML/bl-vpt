package transports

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import org.eclipse.xtend.lib.annotations.Data
import bayonet.math.NumericalUtils
import bayonet.distributions.Multinomial

@Data
abstract class InvarianceTransportProblem {
  
  def double _logWeight(Object s)
  def double _cost(Object s1, Object s2)  
  def Object unpack(int i)
  def int size()
  
  def pi() {
    val it = newDoubleArrayOfSize(size)
    for (i : 0 ..< size)
      set(i, _logWeight(unpack(i)))
    Multinomial.expNormalize(it)
    return denseCopy(it)
  }
  def costs() {
    val it = dense(size, size)
    for (i : 0 ..< size) 
      for (j : 0 ..< size)
        set(i, j, _cost(unpack(i), unpack(j)))
    return it
  }
  def TransportProblem transport() {
    new TransportProblem(costs, pi, pi)
  }
}