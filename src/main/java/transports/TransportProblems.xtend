package transports

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*

class TransportProblems {
  
  static def ising(int m) {
    new Ising(m).transport
  }
  
  static val smallExample = new TransportProblem(
    denseCopy(#[
      #[1, -3, 3],
      #[2, 0, 5]
    ]),
    denseCopy(#[0.5, 0.5]),
    denseCopy(#[0.1, 0.2, 0.7])
  )
  
  static val tinyExample = new TransportProblem(
    denseCopy(#[
      #[1, -3],
      #[2, 0]
    ]),
    denseCopy(#[0.1, 0.9]),
    denseCopy(#[0.2, 0.8])
  )
  
  def static void main(String [] args) {
    
    val solver = new SimplexSolver
    
    println(solver.solve(smallExample).joint)
    
    println(solver.solve(ising(2)).joint)
    
  }
}