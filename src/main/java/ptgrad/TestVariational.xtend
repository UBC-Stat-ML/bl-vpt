package ptgrad

import java.util.Map
import blang.core.RealVar

abstract class TestVariational extends Test {
  
  new(Map<String, RealVar> variables) {
    super(variables)
  }
  
  
  
}