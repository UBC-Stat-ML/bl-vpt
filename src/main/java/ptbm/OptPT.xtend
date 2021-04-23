package ptbm

import blang.engines.internals.Spline.MonotoneCubicSpline
import blang.engines.internals.factories.PT
import blang.inits.Arg
import blang.inits.DefaultValue

import static extension ptbm.StaticUtils.*

class OptPT extends PT {
  
  @Arg @DefaultValue("100")
  public int minSamplesForVariational = 100
  
  override MonotoneCubicSpline adapt(boolean finalAdapt) { 
    val stats = new AllSummaryStatistics(states)
    if (stats.n > minSamplesForVariational) 
      states.setVariationalApproximation(stats)
    return super.adapt(finalAdapt)
  }
  
}