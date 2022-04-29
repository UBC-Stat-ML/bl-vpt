package ptanalysis;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.Constrained;
import blang.core.LogScaleFactor;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.MHSampler;
import blang.mcmc.SampledVariable;
import blang.mcmc.internals.Callback;
import blang.core.WritableRealVar;

/**
 * Warning: not a general purpose move - specialized to SmallHMM test or similar simple binary cases
 */
public class StdNormalProposalMH extends MHSampler
{
  @SampledVariable
  public WritableRealVar real;
  
  public static StdNormalProposalMH build(WritableRealVar real, List<LogScaleFactor> numericFactors) 
  {
    StdNormalProposalMH result = new StdNormalProposalMH();
    result.real = real;
    result.numericFactors = numericFactors;
    return result;
  }
  
  @Override
  public void propose(Random random, Callback callback)
  {
    final double oldValue = real.doubleValue();
    callback.setProposalLogRatio(0.0);
    real.set(oldValue + random.nextGaussian());  
    if (!callback.sampleAcceptance())
      real.set(oldValue);
  }
}