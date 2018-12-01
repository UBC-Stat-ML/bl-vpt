package ptanalysis

import bayonet.distributions.Random
import org.eclipse.xtend.lib.annotations.Data
import java.util.List

/**
 * Generic type encodes a pair of the form (chain index, epsilon in {+1, -1})
 * For the reversible version, the epsilon is flipped at random at the end of each 
 * transition. It is useful to differentiate the state of just getting out of the 
 * hot chain (the initial state) vs. getting absorbed back.
 */
@Data class TemperatureProcess implements DiscreteMarkovChain<Pair<Integer,Integer>> {
  val List<Double> acceptPrs
  val boolean reversible
  override initialState() { 0 -> 1 }
  override sample(Pair<Integer, Integer> current, Random rand) {
    if (current == absorbingState(0)) return absorbingState(0)
    if (current == absorbingState(1)) return absorbingState(1)
    val proposedNext = current.key + current.value
    // convention is that acceptPrs at index i stores pr between i and i+1, so get i by taking min
    val i = Math.min(current.key, proposedNext)
    val acceptPr = acceptPrs.get(i)
    if (rand.nextBernoulli(acceptPr))
      return proposedNext -> if (shouldFlipAfterAccept(proposedNext)) flip(rand) else current.value
    else
      return current.key ->  if (shouldFlipAfterAccept(proposedNext)) flip(rand) else -current.value
  }
  def boolean shouldFlipAfterAccept(int proposedNext) {
    if (!reversible) return false
    // Keep track of where we came from when hitting the absorbing state
    // to differentiate between just getting out of 0 vs. getting absorbed
    // also when hitting the other end point
    return proposedNext !== absorbingState(0).key && proposedNext !== absorbingState(1).key 
  }
  def static int flip(Random rand) {
    return if (rand.nextBernoulli(0.5)) 1 else -1
  }
  override absorbingState(int index) {
    if (index < 0 || index > 1) throw new RuntimeException
    if (index === 0) 0 -> -1 else acceptPrs.size -> 1
  }
}