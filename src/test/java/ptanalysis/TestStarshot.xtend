package ptanalysis

import org.junit.Test

class TestStarshot {
  @Test
  def void test() {
    println(
      StarshotApproximations::acceptPr(
        2.0, 1.0, 
        4.0, 1.0, 
        0.5,
        100
      )
    )
  }
}