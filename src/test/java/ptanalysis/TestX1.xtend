package ptanalysis

import org.junit.Test
import org.junit.Assert

class TestX1 {
  @Test
  def void test() {
    Assert::assertEquals(
      1.0,
      X1Approximations::acceptPr(
        2.0, 1.0, 
        4.0, 1.0, 
        0.5,
        1000 
      ),
      0.01
    )
  }
}