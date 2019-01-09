package ptanalysis

import viz.core.Viz
import viz.core.PublicSize
import viz.core.Viz.PrivateSize
import blang.inits.ConstructorArg
import blang.inits.experiments.Experiment
import blang.inits.DesignatedConstructor
import blang.inits.DefaultValue
import blang.inits.Arg
import java.util.Optional

class PathViz extends Viz {
  val Paths paths
  
  @Arg Optional<Integer> boldTrajectory
  
  @DesignatedConstructor
  new(
    @ConstructorArg("swapIndicators") Paths paths, 
    @ConstructorArg("size") @DefaultValue("height", "300") PublicSize publicSize
  ) {
    super(publicSize)
    this.paths = paths
  }
  
  val baseWeight = 0.05f
  override protected draw() {
    
    for (c : 0 ..< paths.nChains) {
      if (boldTrajectory.orElse(-1) == c)
        strokeWeight(6 * baseWeight)
      else
        strokeWeight(baseWeight)
      setColour(c)
      val path = paths.get(c)
      for (i : 1 ..< paths.nIterations)
        line((i-1), path.get(i-1) + 0.5f, i, path.get(i) + 0.5f)
    }
  }
  
  def void setColour(int chainIndex) {
    val from = color(204, 102, 0)
    val to = color(0, 102, 153)
    val interpolated = lerpColor(from, to, 1.0f * chainIndex / paths.nChains)
    stroke(interpolated)
  }
  
  override protected privateSize() { new PrivateSize(paths.nIterations, paths.nChains) }
  static def void main(String [] args) { Experiment::start(args) }
}