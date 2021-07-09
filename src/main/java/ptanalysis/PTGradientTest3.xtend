package ptanalysis

import ptanalysis.MCTest.ProbabilitySpace
import java.util.ArrayList
import java.util.List
import blang.distributions.Generators
import java.util.Random

import static java.lang.Math.*

import static extension ptanalysis.MCTest.*

class PTGradientTest3 implements ProbabilitySpace {
  
  var rand = new Random(1)
  val int n
  val double phi
  
  new (int n, double phi) {
    this.phi = phi
    this.n = n
    Xs = new ArrayList
    for (i : 0 ..< n) {
      Xs.add(null) 
    }
  }
  
  def D(int i) { 
    W(i, X(i+1)) + W(i+1, X(i)) - W(i, X(i)) - W(i+1, X(i+1))
  }

  def R(int i) {
    return exp(D(i))
  }

  def double beta(int i) {
    if (i == n - 1) return 1.0
    return 1.0 * i / (n - 1)
  }
  
  def double mu(int i) {
    return phi * beta(i)
  }
  
  val List<Double> Xs
  
  def X(int i) { 
    if (Xs.get(i) === null)
      Xs.set(i, Generators::normal(rand, 0.0, 1.0 / beta(i)))
    return Xs.get(i)
  }
  
  def rejectRate(int i) {
    1.0 - E[min(R(i), 1)]
  }
  
  override next() {
    for (i : 0 ..< Xs.size) {
      Xs.set(i, null) 
    }
  }
  
  
  def W(int i, double value) {
    return -pow(value - mu(i), 2) / 2.0 
  }
  
  def Z(int i) {
    return sqrt(2.0 * PI)
  }
  
  def static void main(String [] args) {
    
    // direct
    new PTGradientTest3(2, 0.5) => [
      
      println("Direct")
      println(rejectRate(0))
      
    ]
    
    new PTGradientTest3(3, 0.0) => [
      
      
      
    ]
  }
 
  
}