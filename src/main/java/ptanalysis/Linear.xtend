package ptanalysis

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*

import bayonet.math.CoordinatePacker

class Linear {
  
  val N = 4
  val p = new CoordinatePacker(#[N+1, 2])
  
  def c(int i, int sign) { p.coord2int(i, sign) }
  
  def r(int i, int d) { (if (d ==0) 0.3 else 0.3)  }
  def s(int i, int d) { 1.0 - r(i, d)}
  
  val sol = solve
  
  def a(int i, int sign) { sol.get(c(i, sign)) }
  
  def c(int i) { a(i,1) + a(i-1,0) }
  def d(int i) { a(i,1) - a(i-1,0) }
  
  def solve() {
    val coefs = dense(p.size, p.size)
    val b = dense(p.size)
    
    for (i : 0 .. N) {
      
      var eqIdx = c(i, 0)
      if (i == N) {
        coefs.set(eqIdx, c(i, 1), 1)
      } else {
        coefs.set(eqIdx, c(i, 1), -1)
        coefs.set(eqIdx, c(i+1, 1), s(i+1,1))
        coefs.set(eqIdx, c(i, 0), r(i+1,1))
        
        b.set(eqIdx, -s(i+1,1) - r(i+1,1))
      }
      
      eqIdx = c(i, 1)
      if (i == 0) {
        coefs.set(eqIdx, c(0, 0), 1)
        coefs.set(eqIdx, c(0, 1), -1)
        
        b.set(eqIdx, 1)
      } else {
        coefs.set(eqIdx, c(i,0), -1)
        coefs.set(eqIdx, c(i-1, 0), s(i,0))
        coefs.set(eqIdx, c(i, 1), r(i,0))
        
        b.set(eqIdx, -s(i,0) - r(i,0))
      }
      
    }
    
    return coefs.lu.solve(b)
  }
  
  def roundTrip_analytic() {
    (1.0 + N) * (2.0 + E(0) + E(1))
  }
  
  def numerical() {
    a(0,0)
  }
  
  def E(int d) {
    (1 .. N).map[r(it,d) / s(it,d)].reduce[x,y|x+y]
  }
  
  
  
  def analytic() {
    var double result = N + 1
    for (n : 1 .. N) 
      result += println(2.0 * n * (r(n,0) /  s(n,1)))
    return result
  }
  
  
  
  
  def static void main(String [] args) {
    
    val it = new Linear
    println(numerical)
    println(analytic)
    //println(numerical)
    
    
    //println(s(2,1) * d(1))
    
//    println(a(N,0))
//    
//    val weird = 2 * N + 1
//    
//    println(weird)
    
    
    //println(''' «2 * a(N-1,0)» «c(N) - d(N)» «-2.0 * d(N)» «4.0 * N / s(N)»''')
    
    // println("" + (2*a(N-1,0)) + " " + (2.0/s(N)))  // NO
    
    //println("" + c(N) + " " + (-d(N)))
    
    //println("" + a(N,0) + " " + (r(N) + s(N) * (1.0 + a(N-1,0))))
    
//    for (i : 1 .. N) 
//      println("" + i + " " + (s(i) * d(i)) + " " + (-2.0*i))
    
    
//    println(s)
    
    
//    println(closedForm)
//    println(s.get(c(0, 0)))
//    
//    println(s.get(c(N, 0)))
    
  }
  
  
}