package ptanalysis

import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import ptanalysis.MCTest.ProbabilitySpace
import java.util.Random
import blang.distributions.Generators
import static java.lang.Math.*

import static extension ptanalysis.MCTest.*
import java.util.ArrayList
import org.apache.commons.math3.distribution.NormalDistribution

@Data
class PTGradientTest implements ProbabilitySpace {
  
  val double delta
  
  val rand = new Random(1)
  
  def double mu(int i) { if (i === 0) 0.0 else if (i === 1) delta else throw new RuntimeException }
  
  val List<Double> Xs = new ArrayList(#[null, null])
  
  def X(int i) { Xs.get(i) }
  
  def W(int i, double x) { 0.5 * ((x - mu(i)) ** 2) }
  
  def W(int i)  { W(i, X(i)) }
  def tW(int i) { W(i, X(1-i)) }
  
  def Wp(double x) { delta - x }
  def Wp() { delta - X(1) }
  def tWp() { delta - X(0) }
  
  def D() { -tW(0) - tW(1) + W(0) + W(1) }
  
  def R() { exp(D) }
  
  def T() { if (R >= 1.0) 1.0 else 0.0 }
  
  def U() { 1.0 - T }
  
  def H() { exp(-W(0) -W(1)) / 2.0 / PI }
  def Hp() { - H * Wp }
  def Rp() { R * (Wp - tWp) }
  
  def tH() { exp(-tW(0) -tW(1)) / 2.0 / PI }
  def tHp() { -tH * tWp }
  
  override next() {
    for (i : 0 .. 1) 
      Xs.set(i, Generators::normal(rand, mu(i), 1.0))
  }
  
  def static double analyticRejectRate(double delta) { 1.0 - analyticAcceptRate(delta) }
  def static double analyticRejectGradient(double delta) { -analyticAcceptGradient(delta) }
  
  def static double analyticAcceptRate(double delta) {
    (2.0 * Phi(- sqrt(delta * delta / 2.0)))
  }
  
  def static double analyticAcceptGradient(double delta) {
    - exp(- delta * delta / 4.0) / sqrt(PI)
  }
  
  def static void main(String [] args) {
    val delta = 2.1
    val analyticObjective = analyticAcceptRate(delta) // from Atchade et al (this is an accept!)
    val analyticGradient = analyticAcceptGradient(delta)
    new PTGradientTest(delta) => [
      
      
//      val e6 = 2.0 * E[T * Hp / H]
//      println("e6 = " + e6)
      
//      val simplified = -2.0 * Covar([T], [Wp])
//      println("simplified = " + simplified)
      
//      println( "e4 = " + E[Rp * U] )
//      
//      val e5 = E[T * tHp / t]

      println("LHS = accept = " + E[min(R, 1)])
      val SKL = 1.0 - Math::sqrt(0.5*(E[tW(0) + tW(1) - W(0) - W(1)]))
      println("RHS = 1- sqrt(SKL) = " + SKL)
      println("sqrt 0.5 MC SD = " + Math::sqrt(0.5*(mcSE[tW(0) + tW(1) - W(0) - W(1)])))
      println("obj MC SD = " + mcSE[min(R, 1)])
      
      println("Checking D is N(-d^2, 2d^2)")
      println( "E: " + E[D] + " " +  -(delta ** 2))
      println( "Var: " + Var[D] + " " + (2.0 * (delta ** 2)))
      println("---")
//      
      println("Checking Atchade formula")
      println( E[min(R, 1)] + " " + analyticObjective) // this is an acceptance!
      println("---")
      
      
//      
      println("Analytic gradient = " + analyticGradient)
//      
//      var firstExpr = E[Hp * R * U / H] + E[Rp * U] + E[Hp * T / H]
//      println("first expr = " + firstExpr)
//      
//      var e1 = 2.0 * E[T * tHp / tH]
//      println("e1 = " + e1)
//      
//      {
//        var e2 = E[Hp * R * U / H]
//        var e3 = E[T * tHp / tH]
//        println("e2,e3 = " + e2 + " " + e3)
//      }
//      
//      var finalExpr = 2.0 * (E[T] * E[Wp] - E[T * tWp])
//      println("final expr = " + finalExpr)
//      
//      
      
      
      println("cross term: " + E[T * Wp])
      println("ET: " + E[T])
      println("EWp: " + E[Wp])
      
      println("MC SD for cross term: " + mcSE[T * Wp])
      println("MC SD for T: " + mcSE[T])
      println("MC SD for Wp: " + mcSE[Wp])
      
      var oldExpr = 2.0 * Covar([T], [Wp]) // this is the gradient of a rejection, so sign flip is expected!
      println("old expr = " + oldExpr) // was OK up to a sign!  -0.4168412851034218 vs. -0.41691832364572884
      
      
      
      
      /*

        Checking D is N(-d^2, 2d^2)
        E: -1.210048948177337 -1.2100000000000002
        Var: 2.4213030214426956 2.4200000000000004
        ---
        Checking Atchade formula
        0.4367251391481788 0.43667663367489085
        ---
        Analytic gradient = -0.41691832364572884
        first expr = -0.41695887840871537
        e1 = -0.06333508601269157
        e2,e3 = -0.03169735776739868 -0.0317055723508891
        final expr = -0.06339924892925598
        old expr = -0.4168412851034218

       */
    ]
    
  }
  
  def static Phi(double x) {
    val dist = new NormalDistribution(0.0, 1.0)
    return dist.cumulativeProbability(x)
  }
  
}