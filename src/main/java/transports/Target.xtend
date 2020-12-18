package transports

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import org.eclipse.xtend.lib.annotations.Data
import bayonet.math.CoordinatePacker

@Data
abstract class Target {
  val CoordinatePacker indexer
  def double gamma(int [] s)
  def double cost(int [] s1, int [] s2) 
  def pi() {
    val it = dense(indexer.size)
    for (i : 0 ..< indexer.size)
      set(i, gamma(unpack(i)))
    it /= sum
    return it
  }
  def costs() {
    val it = dense(indexer.size, indexer.size)
    for (i : 0 ..< indexer.size) 
      for (j : 0 ..< indexer.size)
        set(i, j, cost(unpack(i), unpack(j)))
    return it
  }
  def TransportProblem transport() {
    new TransportProblem(costs, pi, pi)
  }
  def unpack(int i) {
    indexer.int2coord(i)
  }
}