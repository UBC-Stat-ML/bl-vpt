package ptgrad.is

import org.eclipse.xtend.lib.annotations.Data
import java.util.List

@Data
class ChainPair {
  val List<Double> betas
  val List<List<Sample>> samples
}