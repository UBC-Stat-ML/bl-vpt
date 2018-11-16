package ptanalysis

import bayonet.distributions.Random
import org.junit.Test
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import org.junit.Assert

class AbsPrsMCTest {
  val int N = 5
  
  @Test
  def void test() {
    val start = 3
    val abs = new AbsorptionProbabilities(rw)
    Assert.assertEquals(abs.absorptionProbability(start, 0), numerical(rw, start, 0, N - 1), 0.01) 
  }
  
  def static <S> double numerical(DiscreteMarkovChain<S> chain, S start, S s0, S s1) {
    val stats = new SummaryStatistics
    val rand = new Random(1)
    for (i : 0 .. 1_000_000) {
      var state = start
      while (state != s0 && state != s1) {
        state = chain.sample(state, rand)
      }
      stats.addValue(if (state == 0) 1 else 0)
    }
    return stats.getMean
  }
  
  val rw = new DiscreteMarkovChain<Integer> {
    override initialState() { 1 }
    override sample(Integer current, Random rand) {
      if (current == absorbingState(0) || current == absorbingState(1)) return current
      return if (rand.nextBernoulli(0.5)) current+1 else current-1
    }
    
    override absorbingState(int index) {
      if (index == 0) 0 else N - 1
    }
    
  }
}