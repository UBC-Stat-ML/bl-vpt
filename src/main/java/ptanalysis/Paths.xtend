package ptanalysis

import java.util.List
import java.io.File
import briefj.BriefIO
import java.util.ArrayList
import blang.inits.ConstructorArg
import blang.inits.Input
import blang.inits.DesignatedConstructor
import blang.inits.DefaultValue

class Paths {
  val List<List<Integer>> paths
  
  /**
   * The list of temperature indices visited by the particle started 
   * at the given input chain index.
   */
  def List<Integer> get(int chainIndexAtBeginning) {
    return paths.get(chainIndexAtBeginning)
  }
  
  def int nChains() { return paths.size }
  def int nIterations() { return paths.get(0).size }
  
  @DesignatedConstructor
  new(
    @Input(formatDescription = "Path to csv file swapIndicators") String swapIndicatorPath, 
    @ConstructorArg("startIteration") @DefaultValue("0") int startIteration, 
    @ConstructorArg("endIteration")   @DefaultValue("INF") int endIteration 
  ) {
    val swapIndicators = new File(swapIndicatorPath)
    val nChains = nChains(swapIndicators)
    val List<List<Integer>> paths = initPaths(nChains)
    var justSwapped = false
    for (line : BriefIO.readLines(swapIndicators).indexCSV) {
      val int sample = Integer.parseInt(line.get("sample"))
      if (sample >= startIteration && sample < endIteration) {
        val int chain = Integer.parseInt(line.get("chain"))
        val int indic = Integer.parseInt(line.get("value"))
        if (justSwapped) {
          justSwapped = false
        } else {
          val p0 = paths.get(chain)
          if (indic == 1) {
            if (justSwapped) throw new RuntimeException
            val p1 = paths.get(chain + 1) 
            paths.set(chain, p1)
            paths.set(chain + 1, p0)
            p1.add(chain)
            p0.add(chain + 1)
            justSwapped = true
          } else {
            p0.add(chain)
          }
        } 
      }
    }
    this.paths = sortPaths(paths)
  }
  
  private def static List<List<Integer>> sortPaths(List<List<Integer>> paths) {
    val result = new ArrayList<List<Integer>>
    val len = paths.get(0).size
    for (i : 0 ..< paths.size) 
      result.add(null)
    for (path : paths) {
      if (path.size != len) throw new RuntimeException
      result.set(path.get(0), path)
    }
    return result
  }
  
  private def static List<List<Integer>> initPaths(int nChains) {
    val result = new ArrayList<List<Integer>>
    for (c : 0 ..< nChains) {
      val path = new ArrayList<Integer>
      path.add(c)
      result.add(path)
    }
    return result
  }
  
  private def static nChains(File swapIndicators) {
    var max = Integer.MIN_VALUE
    for (line : BriefIO.readLines(swapIndicators).indexCSV) {
      val int chain = Integer.parseInt(line.get("chain"))
      val int sample = Integer.parseInt(line.get("sample"))
      max = Math.max(max, chain)
      if (sample > 0)
        return max + 1
    }
    return max + 1
  }
}