package ptanalysis

import org.junit.Test
import org.junit.Assert
import bayonet.math.NumericalUtils

class TempProcessTest {
  
  @Test
  def void test() {
    val pr = 0.6
    val prs = #[pr]
    for (rev : #[true, false]) {
      val mc = new TemperatureProcess(prs, rev)
      val abs = new AbsorptionProbabilities(mc)
      Assert.assertEquals(pr, abs.absorptionProbability(mc.initialState, mc.absorbingState(1)), NumericalUtils::THRESHOLD)
    }
  }
}