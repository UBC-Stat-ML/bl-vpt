package ptgrad.is

import org.eclipse.xtend.lib.annotations.Data
import java.util.List
import java.util.ArrayList

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
}