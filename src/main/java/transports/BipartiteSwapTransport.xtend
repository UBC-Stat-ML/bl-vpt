package transports

import java.util.Set
import briefj.Indexer
import java.util.LinkedHashSet
import org.apache.commons.math3.util.Combinations
import org.apache.commons.math3.util.CombinatoricsUtils
import com.google.common.collect.Sets

class BipartiteSwapTransport extends 
      InvarianceTransportGeneralSpace<Set<Integer>> { // the set of integer is the set of states in the first component
  
  val double[][] logWeights // state -> energy ladder -> logWeight (i.e., -energy)
  val int sizeOfEachComponent
  
  new(int sizeOfEachComponent, double [][] logWeights) {
    super(new Indexer<Set<Integer>>(createSets(sizeOfEachComponent))) 
    this.logWeights = logWeights
    this.sizeOfEachComponent = sizeOfEachComponent
  }
  
  def static Set<Set<Integer>> createSets(int sizeOfEachComponent) {
    val it = new LinkedHashSet<Set<Integer>>
    for (subset : new Combinations(2*sizeOfEachComponent,sizeOfEachComponent))
      add(new LinkedHashSet(subset))
    return it
  }
  
  override logWeight(Set<Integer> s) {
    var it = 0.0
    for (i : 0 ..< sizeOfEachComponent)
      it += logWeights.get(i).get(if (s.contains(i)) 0 else 1)
    return it
  }
  
  override cost(Set<Integer> s1, Set<Integer> s2) {
    Sets.intersection(s1, s2).size
  }
  
  def static void main(String [] args) {
    println(createSets(4).size)
    println(CombinatoricsUtils.binomialCoefficient(8,4))
  }
  
}