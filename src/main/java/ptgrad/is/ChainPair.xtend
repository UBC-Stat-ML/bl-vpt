package ptgrad.is

import org.eclipse.xtend.lib.annotations.Data
import java.util.List
import java.util.ArrayList
import bayonet.distributions.Random

@Data
class ChainPair {
  val List<Double> betas
  val List<List<Sample>> samples
  
  def ChainPair addAntitheticSamples() {
    if (betas.size !== 2) throw new RuntimeException
    val newSamples = new ArrayList<List<Sample>>
    for (i : 0 ..< 2) {
      val other = 1 - i
      newSamples.add(new ArrayList(samples.get(other).map[importanceSample(betas.get(i))]))
    }
    for (i : 0 ..< 2) {
      newSamples.get(i).addAll(samples.get(i))
    }
    return new ChainPair(betas, newSamples)
  }
  
  def ChainPair addMCMCAntitheticSamples(Random rand) {
    val newSamples = new ArrayList<List<Sample>>
    for (i : 0 ..< 2) {
      newSamples.add(new ArrayList(samples.get(i)))
    }
    for (n : 0 ..< samples.get(0).size) {
      val newOne = communicationStep(rand, betas.get(0), betas.get(1), samples.get(0).get(n), samples.get(1).get(n))
      newSamples.get(0).add(newOne.key)
      newSamples.get(1).add(newOne.value)
    }
    
    return new ChainPair(betas, newSamples)
  }
  
  def static Pair<Sample,Sample> communicationStep(Random rand, double beta1, double beta2, Sample sample1, Sample sample2) {
    val logRatio = sample1.logDensity(beta2) + sample2.logDensity(beta1) -
                   sample1.logDensity(beta1) - sample2.logDensity(beta2)
    val pr = Math::min(1.0, Math::exp(logRatio))
    if (rand.nextBernoulli(pr))
      return Pair.of(sample2, sample1)
    else
      return Pair.of(sample1, sample2)
  }
}