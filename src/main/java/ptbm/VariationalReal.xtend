package ptbm

import blang.core.WritableRealVar
import java.util.Random
import blang.mcmc.Samplers
import blang.core.RealDistribution
import blang.types.AnnealingParameter

@Samplers(VariationalRealSampler)
class VariationalReal implements WritableRealVar {
  
  double value = 0.0
  public RealDistribution variational = null
  
  // ID used to match up variational approximations across copies:
  public final VariableIdentifier identifier = new VariableIdentifier
  
  override set(double value) {
    this.value = value
  }
  
  override doubleValue() {
    return value
  }
  
  def boolean isVariationalActive() {
    return variational !== null
  }
  
  def void variationalSample(Random rand) {
    this.value = variational.sample(rand)
  }
  
  def double variationalLogDensity() {
    variational.logDensity(value) 
  }
  
  override String toString() {
    return Double.toString(this.value)
  }
  
}