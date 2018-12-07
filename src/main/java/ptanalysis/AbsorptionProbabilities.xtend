package ptanalysis

import briefj.Indexer
import java.util.LinkedList
import bayonet.distributions.ExhaustiveDebugRandom

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import org.apache.commons.lang3.time.StopWatch

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
//    println("M=\n" +M)
    val soln = M.lu.solve(b)
//    println("b=\n" + b)
//    println("x=\n" + soln)
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
  
  
  def static void main(String [] args) {
    val p = "/Users/bouchard/experiments/ptanalysis-nextflow/work/f6/5b6eb6e79dc9ea435be9ec762f5b06/multiBenchmark/work/8b/b41a6750f9cef69c97747561b72ddd/results/all/2018-12-04-10-06-42-HVSzp8mU.exec/samples/energy.csv"
    val go = new GridOptimizer(new Energies(p), false, 1)    
    for (nChains : (1..10).map[Math::pow(2, it) as int]) 
      for (useOld : #[true, false]) {
        GridOptimizer::useOld = useOld
        val timer = new StopWatch => [start]
        go.initializedToUniform(nChains)
        val pr = go.rejuvenationPr
        println('''«useOld», «nChains», «timer.time», «pr»''')
    }
  }
}