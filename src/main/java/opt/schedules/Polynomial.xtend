package opt.schedules

import opt.schedules.Schedule
import blang.inits.Arg
import blang.inits.DefaultValue

class Polynomial extends Schedule {
  
  @Arg   @DefaultValue("-0.6")
  var double exponent = -0.6
  
  override next(int i) {
    if (exponent > 0) throw new RuntimeException
    return (i + 1) ** exponent
  }
  
}