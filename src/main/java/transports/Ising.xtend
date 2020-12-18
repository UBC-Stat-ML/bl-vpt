package transports

import bayonet.math.CoordinatePacker
import blang.validation.internals.fixtures.Functions
import briefj.collections.UnorderedPair
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

@Data
class Ising extends Target {
  val int m
  val List<UnorderedPair<Integer, Integer>>  pairs
  val beta = Math::log(1 + Math::sqrt(2.0)) / 2.0 // critical point
  
  new (int m) {
    super({
      val int[] sizes = newIntArrayOfSize(m * m)
      for (v : 0 ..< m*m) 
        sizes.set(v, 2)
      new CoordinatePacker(sizes)
    })
    this.m = m
    pairs = Functions.squareIsingEdges(m)
  }
  
  override gamma(int [] s) {
    var sum = 0.0
    for (pair : pairs) {
      val first = s.get(pair.first)
      val second = s.get(pair.second)
      sum += (2*first-1)*(2*second-1)
    }
    return Math::exp(beta * sum)
  }
  
  override cost(int [] s1, int [] s2) {
    StaticUtils::intersectionSize(s1, s2)
  }
}