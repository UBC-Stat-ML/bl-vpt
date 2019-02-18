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
  
                         @DefaultValue("true")
  @Arg boolean useAcceptRejectColours = true
  
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
    translate(0.5f, 0.5f)
    for (c : 0 ..< paths.nChains) {
      if (boldTrajectory.orElse(-1) == c)
        strokeWeight(6 * baseWeight)
      else
        strokeWeight(baseWeight)
      if (!useAcceptRejectColours)
        setColour(c)
      val path = paths.get(c)
      for (i : 1 ..< paths.nIterations) {
        if (useAcceptRejectColours)
          setColour(path.get(i-1) != path.get(i))
        line((i-1), path.get(i-1), i, path.get(i))
        stroke(0, 0, 0)
        ellipse(i - 1, path.get(i-1), 0.1f, 0.1f)
      }
      ellipse(paths.nIterations - 1, path.get(paths.nIterations - 1), 0.1f, 0.1f)
    }
  }
  
  def void setColour(boolean accepted) {
    if (accepted) stroke(0, 204, 0)
    else stroke(204, 0, 0)
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