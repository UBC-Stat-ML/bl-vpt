package transports

import org.eclipse.xtend.lib.annotations.Data
import xlinear.Matrix

@Data
class InvariantTransport {
  val Matrix pi
  val Matrix cost
  
  /**
   * plan:
   * 
   * - solidify solver, one of:
   *    - switch to math commons' simplex solver [could be slow] <- seems better
   *    - stick with regularized [could be slow too, need rounding, lambda param]
   * 
   * - proof of concept:
   *    - multiple PT chains
   * 
   * - other apps
   *    - skipping PT
   *    - block Gibbs, e.g. Ising
   *    - HMC?
   * 
   */
}