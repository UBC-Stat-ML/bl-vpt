package ptanalysis

import blang.inits.Implementations

@Implementations(NormalEnergySwapPrs)
interface SwapPrs {
  /**
   * Swap pr between the two annealing parameters.
   */
  def double between(double annealParam1, double annealParam2)
}