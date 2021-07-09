package ptanalysis

import edu.umontreal.kotlingrad.api.Vec
import edu.umontreal.kotlingrad.api.SVar
import edu.umontreal.kotlingrad.api.DReal

class TestKG {
  
  def static void main(String [] args) {
    val x = new SVar<DReal>(new DReal(1.1), "Test")
    val y = new SVar<DReal>(new DReal(1.5), "Test2")
    val z = x.times(y)
    
    val array = newArrayOfSize(2)
    array.set(0, new kotlin.Pair(x, 2))
    array.set(1, new kotlin.Pair(y, 3))
    
    
    //println(z.invoke(array))
    //val inv = 
    //println(z.grad.invoke(array))
    
    
    val g = z.grad
    val c = g.get(x).invoke(array)
    println(c.invoke())
  }
}