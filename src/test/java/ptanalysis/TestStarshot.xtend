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
        1000 
      ),
      0.01
    )
  }
}