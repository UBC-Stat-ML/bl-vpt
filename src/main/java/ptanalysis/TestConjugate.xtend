package ptanalysis

import ptgrad.ConjugateNormal
import blang.core.WritableRealVar

class TestConjugate {
  
  def static void main(String [] args) {
    val conj = new ConjugateNormal
    val toy = new ptgrad.ToyNormal => [mu0 = 1.5; variance = 0.5] 
    
    for (beta : #[0.2, 0.3]) {
      println("beta = " + beta)
      println
      for (x : #[1.2, 3.5]) {
        (conj.variables.values.get(0) as WritableRealVar).set(x)
        (toy.variables.values.get(0) as WritableRealVar).set(x)
        println("conj " + conj.logDensity(beta))
        println("toy " + toy.logDensity(1.0 - beta))
        println(conj.logDensity(beta) - toy.logDensity(1.0 - beta))
        println("grad conj " + conj.gradient(beta).get(0))
        println("grd toy " + toy.gradient(1.0 - beta).get(0))
        println(conj.gradient(beta).get(0) - toy.gradient(1.0 - beta).get(0))
        println
      }
    }
  }
}