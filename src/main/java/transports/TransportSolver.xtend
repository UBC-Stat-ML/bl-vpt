package transports

interface TransportSolver {
  def Plan solve(TransportProblem problem)
}