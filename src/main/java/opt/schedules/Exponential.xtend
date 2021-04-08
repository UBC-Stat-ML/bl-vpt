package opt.schedules

import blang.inits.Arg
import blang.inits.DefaultValue

class Exponential extends Schedule {
  
  @Arg @DefaultValue("0.8")
  var   double base = 0.8
  
  override next(int i) {
    base ** i
  }
  
}