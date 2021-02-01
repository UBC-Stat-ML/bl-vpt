package ptgrad.is

import org.eclipse.xtend.lib.annotations.Data
import java.util.List

@Data
class ChainPair {
  val double beta1
  val double beta2
  val List<Sample> samples1
  val List<Sample> samples2
}