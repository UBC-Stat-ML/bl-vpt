package opt.schedules

import blang.inits.Implementations

@Implementations(Polynomial, Exponential, Constant)
abstract class Schedule {
  
  var int i = 0
  
  def double next(int i) 
  
  def double nextScaled(double initialScale) {
    val result = next(i++) * initialScale
    blang.System.out.println('''stepsize [ value=«result» type=«this.class.simpleName» ]''')
    return result
  }
  
}