package ptbm.models

import blang.types.Index
import bayonet.math.NumericalUtils
import briefj.BriefIO

class Utils {
  
  def static avoidBoundaries(double p) {
    if (p === 0.0) return NumericalUtils::THRESHOLD
    if (p === 1.0) return 1.0 - NumericalUtils::THRESHOLD
    return p
  }
  
  // from blogobayes
  def static boolean isControl(Index<String> index) {
    switch (index.key) {
      case "control" : true
      case "vaccinated" : false
      default : throw new RuntimeException
    }
  }
  
  def static double mu(int k, int j, double box, int dim) {
    return 
      if      (k == 1) box
      else if (k == 2) -box
      else if (k == 3 && j <= dim/2) -box/2.0
      else if (k == 3 && j > dim/2) box/2.0
      else if (k == 4 && j <= dim/2) box/2.0
      else -box/2.0;
  }
  
  def static double w(int k) {
    return if (k <= 2) 1.0 else 2.0
  }
  
  def static void main(String [] args) {
    val x = BriefIO.resourceToString("/conifer/io/dna-iupac-encoding.txt")
    println(x)
  }
}