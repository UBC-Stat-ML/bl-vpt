package ptanalysis

import briefj.Indexer
import java.util.LinkedList
import bayonet.distributions.ExhaustiveDebugRandom

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import xlinear.Matrix

class AbsorptionProbabilities<S> {
  val Indexer<S> index
  val Matrix B
  
  new(DiscreteMarkovChain<S> chain) {
    index = index(chain, chain.absorbingState(0), chain.absorbingState(1))
    val P = dense(index.size, index.size)
    for (current : index.objects) {
      val i = index.o2i(current)
      val random = new ExhaustiveDebugRandom
      while (random.hasNext) {
        val next = chain.sample(current, random)
        val j = index.o2i(next)
        P.increment(i, j, random.lastProbability)
      }
    }
    val Q = P.slice(2, index.size, 2, index.size)
    val N = (identity(index.size - 2) - Q).inverse
    val R = P.slice(2, index.size, 0, 2)
    this.B = N * R
  }
  
  def double absorptionProbability(S start, S end) {
    val j = index.o2i(end)
    if (j !== 0 && j !== 1) throw new RuntimeException("" + end + " is not one of the two analysed absorbing states.")
    val i = index.o2i(start) - 2
    return B.get(i,j)
  }
  
  /**
   * Indexing guarantees absorbing states s0 and s1 are indexed 0 and 1
   */
  def private static <S> Indexer<S> index(DiscreteMarkovChain<S> chain, S s0, S s1) {
    val result = new Indexer<S> => [ addToIndex(s0, s1) ]
    val queue = new LinkedList => [ add(chain.initialState) ]
    while (!queue.empty) {
      val current = queue.poll
      result.addToIndex(current)
      val random = new ExhaustiveDebugRandom
      while (random.hasNext) {
        val next = chain.sample(current, random)
        if (!result.containsObject(next)) queue.add(next)
      }
    }
    return result
  }
}