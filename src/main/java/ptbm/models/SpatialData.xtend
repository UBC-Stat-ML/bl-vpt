package ptbm.models

import blang.inits.ConstructorArg
import blang.inits.DesignatedConstructor
import briefj.collections.UnorderedPair
import com.rits.cloning.Immutable
import java.io.File
import java.util.LinkedHashSet
import org.apache.commons.math3.linear.EigenDecomposition
import org.eclipse.xtend.lib.annotations.Data
import xlinear.DenseMatrix
import xlinear.Matrix
import xlinear.SparseMatrix

import static briefj.BriefIO.*
import static xlinear.MatrixOperations.*

import static extension xlinear.MatrixExtensions.*

@Immutable
@Data
class SpatialData {
  
  val SparseMatrix adjacency
  val DenseMatrix car_eigendecomposition
  val SparseMatrix D
  
  @DesignatedConstructor
  new(@ConstructorArg(value = "adjacency", description = "Should be 1 indexed, will take care of translating.") File adjFile) {
    adjacency = parseROutput(adjFile)
    checkSymmetric(adjacency)
    D = neighbourhoodSizes(adjacency, 1.0)
    car_eigendecomposition = car_eigendecomposition(adjacency)
  }
  
  def static DenseMatrix car_eigendecomposition(Matrix adj) {
    val n = adj.nRows
    if (n !== adj.nCols) throw new RuntimeException
    System.out.println('''Caching eigendecomp of a «n»-by-«n» matrix (current impl not using sparsity)''')
    val result = dense(adj.nRows)
    val D_minus_half = neighbourhoodSizes(adj, -1.0/2.0)
    val product = D_minus_half * adj * D_minus_half
    val eigen = new EigenDecomposition(product.toCommonsMatrix)
    for (i : 0 ..< n)
      result.set(i, eigen.getRealEigenvalue(i))
    return result.readOnlyView
  }
  
  def static fast_log_det(Matrix eigenVectors, double alpha) {
    var sumOfLogs = 0.0
    // from Jin, Carlin, and Banerjee (2005) 
    // see also https://mc-stan.org/users/documentation/case-studies/mbjoseph-CARStan.html
    for (i : 0 ..< eigenVectors.nEntries) {
      val factor = 1.0 - alpha * eigenVectors.get(i)
      if (factor <= 0.0)
        throw new RuntimeException
      sumOfLogs += Math::log(factor)
    }
    return sumOfLogs
  }
  
  def edges() {
    val result = new LinkedHashSet<UnorderedPair<Integer,Integer>>
    adjacency.visitNonZeros[r, c, v | 
      if (v != 1.0) throw new RuntimeException
      result.add(UnorderedPair.of(r, c))
    ]
    return result
  }
  
  def static checkSymmetric(SparseMatrix m) {
    m.visitNonZeros[r, c, v| 
      if (v != m.get(c, r))
        throw new RuntimeException
    ]
  }
  
  def static SparseMatrix neighbourhoodSizes(Matrix adj, double exp) {
    val result = sparse(adj.nRows, adj.nCols) 
    for (i : 0 ..< adj.nRows) {
      val nNeighbours = adj.row(i).sum
      result.set(i, i, Math::pow(nNeighbours, exp))
    }
    return result.readOnlyView
  }
  
  def static SparseMatrix parseROutput(File f) {
    val size = readLines(f).splitCSV.first.get.size - 1
    val result = sparse(size, size)
    for (line : readLines(f).splitCSV.skip(1)) {
      val i = Integer::parseInt(line.get(0)) - 1
      for (var int j = 1; j < line.size; j++) {
        result.set(i, j-1, Double::parseDouble(line.get(j)))
      }
    }
    return result.readOnlyView
  }
  
  // checking the math..
  
  def static void main(String [] args) {
    val spatial = new SpatialData(new File("data/scotland_lip_cancer/adj.csv"))
    spatial._check_slow_det
  }
  
  def _check_slow_det() {
    System.out.println("Checking fast_det")
    
    for (alpha : #[0.1, 0.3 ,0.99]) {
      val slow = _slow_log_det(D, alpha, adjacency)
      val fast = fast_log_det(car_eigendecomposition, alpha)
      System.out.println('''diff=«slow - fast» slow=«slow» fast=«fast»''')
    }
    
  }
  
  def static _slow_log_det(Matrix D, double alpha, Matrix W) {
    return (D - alpha * W).cholesky.logDet
  }
  
}