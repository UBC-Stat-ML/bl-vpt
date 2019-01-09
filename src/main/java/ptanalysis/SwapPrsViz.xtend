package ptanalysis

import blang.inits.experiments.Experiment
import viz.core.PublicSize
import blang.inits.DesignatedConstructor
import blang.inits.ConstructorArg
import viz.components.MatrixViz
import xlinear.Matrix

import static xlinear.MatrixOperations.*
import java.util.ArrayList
import blang.inits.DefaultValue
import java.io.File

class SwapPrsViz extends MatrixViz {
  @DesignatedConstructor
  new(
    @ConstructorArg("energies") File energiesFile, 
    @ConstructorArg("mode") ApproximationMode mode,
    @ConstructorArg("size") @DefaultValue("height", "300") PublicSize publicSize
  ) {
    super(matrix(energiesFile, mode), greyScale, publicSize)
  }
  
  def static Matrix matrix(File energiesFile, ApproximationMode mode) {
    val allEnergies = new Energies(energiesFile)
    val burnedInEnergies = SwapStaticUtils::preprocessedEnergies(energiesFile)
    val size = allEnergies.moments.keySet.size  
    val params = new ArrayList(allEnergies.moments.keySet).sort
    val result = dense(size, size)
    for (i : 0 ..< size) 
      for (j : 0 ..< size) {
        val param_i = params.get(i)
        val param_j = params.get(j)
        result.set(i, j, switch mode {
          case Normal : allEnergies.swapAcceptPr(param_i, param_j)
          case NormalDiagnostic : if (allEnergies._useBackOff(param_i, param_j)) 1.0 else 0.0
          case MonteCarlo : SwapStaticUtils::estimateSwapPr(param_i, param_j, burnedInEnergies.get(param_i), burnedInEnergies.get(param_j))
          case DenseTemperature : Math.max(0, (1.0 - Math.abs(param_i - param_j) * allEnergies.lambda(Math.min(param_i, param_j) + Math.abs(param_i - param_j) / 2.0)))
          default : throw new RuntimeException
        })
      }  
    return result
  }
  
  def static void main(String[] args) {
    Experiment::start(args)
  }
  
  static enum ApproximationMode {
    Normal,
    MonteCarlo,
    DenseTemperature,
    NormalDiagnostic
  }
}