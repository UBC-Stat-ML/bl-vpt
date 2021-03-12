package ptanalysis

import ptanalysis.MCTest.ProbabilitySpace
import java.util.ArrayList
import java.util.List
import blang.distributions.Generators
import java.util.Random

import static java.lang.Math.*

import static extension ptanalysis.MCTest.*

class PTGradientTest2 implements ProbabilitySpace {
  
  val rand = new Random(1)
  val int n
  val double phi
  
  new (int n, double phi) {
    this.phi = phi
    this.n = n
    Xs = new ArrayList
    Zs = new ArrayList
    for (i : 0 ..< n) {
      Xs.add(null)  // Generators::normal(rand, mu(i), 1.0))
      Zs.add(null)  // Generators::standardNormal(rand))
    }
  }
  
  def D(int i) { 
    W(i, X(i+1)) + W(i+1, X(i)) - W(i, X(i)) - W(i+1, X(i+1))
  }
  
  def gradD(int i) { 
    gradW(i, X(i+1)) + gradW(i+1, X(i)) - gradW(i, X(i)) - gradW(i+1, X(i+1))
  }
  
  def R(int i) {
    return exp(D(i))
  }
  
  def gradR(int i) {
    return gradD(i) * R(i)
  }
  
  def T(int i) {
    if (D(i) >= 0.0) return 1.0 else 0.0
  }
  
  def T2(int i, double phi) {
    if (Z(i+1) - Z(i) <= phi * (beta(i) - beta(i+1))) return 1.0 else 0.0
  }
  
  def T3(int i) {
    if (X(i+1) <= X(i)) return 1.0 else 0.0
  }
  
  def double beta(int i) {
    if (i == n - 1) return 1.0
    return 1.0 * i / (n - 1)
  }
  
  def double mu(int i) {
    return phi * beta(i)
  }
  
  val List<Double> Xs
  val List<Double> Zs
  
  def X(int i) { 
    if (Xs.get(i) === null)
      Xs.set(i, Generators::normal(rand, mu(i), 1.0))
    return Xs.get(i)
  }
  def Z(int i) { 
    if (Zs.get(i) === null)
      Zs.set(i, Generators::standardNormal(rand))
    Zs.get(i)
  }
  
  def H(int i, double x1, double x2) { // NB: skipping Z here but should be fine since cnst
    exp(W(i,x1)) * exp(W(i+1,x2))
  }
  
  def gradH(int i, double x1, double x2) {
    (gradW(i,   x1) + gradW(i+1, x2)) * H(i, x1, x2) // uses the fact W is normalized
  }
  
  def zeta(int i) {
    if (Z(i+1) <= Z(i)) 1.0 else 0.0
  }
  
  def xi(int i, double phi) { zeta(i) - T2(i, phi)}
  
  override next() {
    for (i : 0 ..< Xs.size) {
      Xs.set(i, null) //Generators::normal(rand, mu(i), 1.0))
      Zs.set(i, null) //Generators::standardNormal(rand)) 
    }
  }
  
  def W(int i, double value) {
    return -pow(value - mu(i), 2) / 2.0 - 0.5 * log(2.0 * PI)
  }
  
  def gradW(int i, double value) {
    return beta(i) * (value - mu(i))
  }
  
  def rejectRate(int i) {
    1.0 - E[min(R(i), 1)]
  }
  
  def gradRejectRate(int i) {
    -2.0 * Covar([T(i)], [gradW(i, X(i)) + gradW(i+1, X(i+1))])
  }
  
  def gradRejectRate2(int i) { 
    -2.0 * E[T(i) * (gradW(i, X(i)) + gradW(i+1, X(i+1)))]
  }
  
  def gradRejectRate3(int i) { 
    -2.0 * Covar([T(i)],[(gradW(i+1, X(i+1)) - gradW(i, X(i+1)))])
  } 
  
  def static void main(String [] args) {
    // recheck good old Atchade formula first
    val phi = 0.3
    
//    println('''
//    
//    exact results:
//    
//      accept pr: «PTGradientTest::analyticRejectRate(phi)»
//      reject gradient: «PTGradientTest::analyticRejectGradient(phi)»
//    ''')
//    
//    new PTGradientTest2(2, phi) => [
//      
//      println('''
//        With 2 chains...
//        
//          MC reject: «rejectRate(0)»
//          MC gradient: «gradRejectRate(0)»
//          MC gradient2: «gradRejectRate2(0)»
//      ''')
//      
//      println("ET" + E[T(0)])
//      
////      val i1 = 0
////      val i2 = i1 + 1
////      val first = E[
////        val Hp = gradH(i1, X(i1), X(i2))
////        val R = R(i1)
////        val T = T(i1)
////        val U = 1.0 - T
////        val H = H(i1, X(i1), X(i2))
////        val Rp = gradR(i1)
////        return Hp * R * U / H + Rp * U + Hp * T / H
////      ]
////      println("* start of gradient deriv:" + -first)
//          // ok that works
//    ]
    
    val int n = 10
    println('''
    
    With «n» chains...
    ''')
    
    // now with an intermediate chain
    val myphi = phi //(n-1) *phi
    new PTGradientTest2(n, myphi) => [
      numberMonteCarloIterations = 10000000
      
      
      println("rate(0): " + rejectRate(0))
      println("rate(8): " + rejectRate(6))
      println("grad3(0): " + gradRejectRate3(0))
      println("grad3(8): " + gradRejectRate3(6))
      println("grad2(0): " + gradRejectRate2(0))
      println("grad2(8): " + gradRejectRate2(6))
      println("grad(0): " + gradRejectRate(0))
      println("grad(8): " + gradRejectRate(6))
      
//      val delta = beta(2) - beta(1)
//      val firstTerm = delta * E[T2(1, myphi) * Z(2)]
//      val secondTerm = beta(1) * E[xi(1, myphi) * (Z(1) + Z(2))]
//      println("(b)" + -2.0*(firstTerm-secondTerm))
//      println("(b1)" + firstTerm)
      //println("(b2)" + secondTerm)
//      //println(gradRejectRate(2))
//      // gets 0.002883464291353564
//      
//      var sum = 0.0
//        
//      // println(gradRejectRate2(2)) // same as above
//      println(gradRejectRate2(n-2)) // 1.8546397795273004E-5
//      println(gradRejectRate2(n-2))
//      println(gradRejectRate2(n-2))
//      println(gradRejectRate(n-2))  // -0.004167923192741442
//      
//      print("" + E[T2(1, myphi) * Z(1)] + " vs " + E[T2(1, myphi) * Z(2)]);
//      
//      // this one is OK
//      sum = beta(1) * E[val i = 1; T3(i) * (X(i) - myphi * beta(i))];
//      sum +=    beta(2) * E[val i = 2; T3(1) * (X(i) - myphi * beta(i))];
//      
//      println("(a)" + (-2.0 * sum))
//
//      sum = beta(1) * E[T2(1, myphi) * Z(1)];
//      sum+= beta(2) * E[T2(1, myphi) * Z(2)];
//      println("(b)" + (-2.0 * sum))
      //  -0.0028165642574961205 weird sign flip...
      
//      sum = beta(n-2) * E[T2(n-2, myphi) * Z(n-2)]
//      sum+= beta(n-1) * E[T2(n-2, myphi) * Z(n-1)]
//      println(-2.0 * sum)
      // -0.013573488522102495
      
      
//      println(E[T(0)])   // 0.4153489999999991
//      println(E[T(n-2)]) // 0.4157659999999917
//      
//      println(mcSE[T(0)])  // 4.937495321476466E-4
//      println(mcSE[T(n-2)])// 4.929377041331E-4
      
//      println("estimates")
//      println("frst : " + gradRejectRate2(1))
//      println("scnd : " + gradRejectRate2(2))
//      println("last : " + gradRejectRate2(n-2))
//      estimates
//frst : 0.002748292218237932
//frst : 0.00274234166465623
//last : 0.002743962689784081
      
//      println("mcses:")
//      println("frst : " + mcSE[T(1) * (gradW(1, X(1)) + gradW(2, X(2)))])
//      println("secd : " + mcSE[T(2) * (gradW(2, X(2)) + gradW(3, X(3)))])
//      println("last : " + mcSE[T(n-2) * (gradW(n-2, X(n-2)) + gradW(n-1, X(n-1)))])
    
//    mcses:
//frst : 7.186528988663515E-6
//secd : 1.1646256760668147E-5
//last : 9.098345224772409E-4
      
//      println("ET" + E[T(0)])
//      
//      //println("should be zero: " + E[gradW(2, X(2))])
//          // indeed...
//      
//      val first = E[
//        val i1 = 0
//        val i2 = i1 + 1
//        val Hp = gradH(i1, X(i1), X(i2))
//        val R = R(i1)
//        val T = T(i1)
//        val U = 1.0 - T
//        val H = H(i1, X(i1), X(i2))
//        val Rp = gradR(i1)
//        return Hp * R * U / H + Rp * U + Hp * T / H
//      ]
//      println("start of gradient deriv:" + -first)
//      
//      
//      val simplified = E[
//        val i1 = 0
//        val i2 = i1 + 1
//        val Hp = gradH(i1, X(i1), X(i2))
//        val R = R(i1)
//        val T = T(i1)
//        val U = 1.0 - T
//        val H = H(i1, X(i1), X(i2))
//        val Rp = gradR(i1)
//        return Hp * R / H + Rp 
//      ]
//      println("simplified:" + -simplified)
//      
//      
//      println('''
//      
//        checks:
//        
//          means:
//            «E[X(0)]»
//            «E[X(1)]»
//            
//          variances:
//            «Var[X(0)]»
//            «Var[X(1)]»
//      
//      ''')
      

//      val hyb = E[
//        val Hp = gradH(i1, X(i1), X(i2))
//        val R = R(i1)
//        val T = T(i1)
//        val U = 1.0 - T
//        val H = H(i1, X(i1), X(i2))
//        val Rp = gradR(i1)
//        return Hp * R * U / H + Rp * U + Hp * T / H
//      ]
//      println("weird hybrid" + -hyb)
      
//      println(
//      '''
//        
//          MC reject: «rejectRate(0)»
//          MC gradient: «gradRejectRate(0)»
//      ''')    
]
    
  }
  
}