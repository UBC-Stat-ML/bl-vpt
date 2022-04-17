package ptbm.models

import blang.types.Index
import bayonet.math.NumericalUtils

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
}