package ptgrad.is

import org.eclipse.xtend.lib.annotations.Data
import java.util.List
import java.util.ArrayList
import bayonet.distributions.Random

@Data
class ChainPair {
  val List<Double> betas
  val List<List<Sample>> samples
  
  def void addInPlace(List<Sample> fromOtherChain) {
    for (s : fromOtherChain) {
      for (i : 0 ..< 2) {
        val betaPrime = betas.get(i)
        samples.get(i).add(s.importanceSample(betaPrime)) 
      }
    }
  }
  
  def void addInPlace(ChainPair other) {
    if (this.betas != other.betas) throw new RuntimeException
    for (i : 0 ..< 2)
      this.samples.get(i).addAll(other.samples.get(i))
  }
  
  // Note: this does not ADD, you have to add manually
  // need to do this like that (not in place) to avoid interfering with adding neighbours
  def ChainPair antitheticSamples() {
    if (betas.size !== 2) throw new RuntimeException
    val newSamples = new ArrayList<List<Sample>>
    for (i : 0 ..< 2) {
      val other = 1 - i
      newSamples.add(new ArrayList(samples.get(other).map[importanceSample(betas.get(i))]))
    }
//    for (i : 0 ..< 2) {
//      newSamples.get(i).addAll(samples.get(i))
//    }
    return new ChainPair(betas, newSamples)
  }
  
  // don't do this one in place! would create problems
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
  
  def double ess() {
    ess(samples.get(0)) + ess(samples.get(1))
  }
  
  private static def double ess(List<Sample> samples) {
    val sumWeights = sumWeights(samples, 1)
    val sumSqWeights = sumWeights(samples, 2)
    return Math::pow(sumWeights, 2) / sumSqWeights
  }
  
  private static def double sumWeights(List<Sample> samples, int power) {
    samples.map[Math::pow(weight, power)].reduce[a,b|a+b] 
  }
}