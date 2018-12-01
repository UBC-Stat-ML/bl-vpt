package ptanalysis

import org.junit.Test
import org.junit.Assert

class TestStarshot {
  @Test
  def void test() {
    Assert::assertEquals(
      1.0,
      StarshotApproximations::acceptPr(
        2.0, 1.0, 
        4.0, 1.0, 
        0.5,
        1000 // NB: a bit more than that and gets to zero, probably all the mass gets smaller than integral discretization size
      ),
      0.01
    )
  }
  
  @Test
  def void agreement() {
    for (i : 1 .. 100) {
      StarshotApproximations::useQMC = true
      var qmc = StarshotApproximations::acceptPr(
        2.0, 1.0, 
        4.0, 1.0, 
        0.5,
        i
      )
      StarshotApproximations::useQMC = false
      var num = StarshotApproximations::acceptPr(
        2.0, 1.0, 
        4.0, 1.0, 
        0.5,
        i
      )
      Assert::assertEquals(qmc, num, 0.01)
    }
  }
  
}