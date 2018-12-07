package ptanalysis

import briefj.Indexer
import java.util.LinkedList
import bayonet.distributions.ExhaustiveDebugRandom

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*

class AbsorptionProbabilities<S> {
  
  /**
   * Compute pr hit chain.abs(1)
   */
  def static <S> double compute(DiscreteMarkovChain<S> chain) {
    val index = indexLinearSystem(chain) 
    val M = sparse(index.size, index.size)
    val b = sparse(index.size, 1)
    for (current : index.objects) {
      val i = index.o2i(current)
      M.increment(i, i, -1)
      val random = new ExhaustiveDebugRandom
      while (random.hasNext) {
        val next = chain.sample(current, random)
        val pr = random.lastProbability
        if (next == chain.absorbingState(0)) {
          // nothing to do
        } else if (next == chain.absorbingState(1)) {
          b.increment(i, - pr)
        } else {
          val j = index.o2i(next)
          M.increment(i, j, pr)
        }
      }
    }
    val soln = M.lu.solve(b)
    return soln.get(index.o2i(chain.initialState)) 
  }
  
  def private static <S> Indexer<S> indexLinearSystem(DiscreteMarkovChain<S> chain) {
    val result = new Indexer<S> 
    val s0 = chain.absorbingState(0)
    val s1 = chain.absorbingState(1) 
    val queue = new LinkedList => [ add(chain.initialState) ]
    while (!queue.empty) {
      val current = queue.poll
      result.addToIndex(current)
      val random = new ExhaustiveDebugRandom
      while (random.hasNext) {
        val next = chain.sample(current, random)
        if (!result.containsObject(next) && next != s0 && next != s1) queue.add(next)
      }
    }
    return result
  }
}