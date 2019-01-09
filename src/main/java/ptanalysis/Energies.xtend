package ptanalysis

import blang.inits.Implementations

@Implementations(NormalEnergies, MCEnergies)
interface Energies {
  def double swapAcceptPr(double param1, double param2) 
}