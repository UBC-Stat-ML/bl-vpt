package ptanalysis

import bayonet.distributions.Random

interface DiscreteMarkovChain<S> {
  /**
   * An arbitrary state from which all the other ones can be discovered recursively.
   */
  def S initialState()
  /**
   * Encodes two competing absorbing states
   */
  def S absorbingState(int index) 
  
  def S sample(S current, Random rand)  
}