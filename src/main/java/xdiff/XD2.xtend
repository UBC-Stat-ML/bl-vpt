package xdiff

class XD2 {
  
  /**
   * 
   *  New method:
   * 
   * - identify a set of pure functions (ann, etc)
   * 
   * @MyAnn
   * def double primitive(double x, double y) {
   *    ...
   * }
   * def double primitive_derivative(int index, double x, double y)
   * 
   * 
   * def double user(double x, double y, double z) {
   *  double w = primitive(x, y)
   * 
   * }
   * 
   * - automatically generated bloated version
   * 
   * def Var<Double> primitive(Var<Double> x, Var<Double> y) {
   *  return new Var(...)
   * }
   * 
   * - then user builds the graph
   * - then generate code that calls primitive(..,..) and primitive_derivative(..,..) in the right order
   * 
   * 
   * 
   * - but then would need to ensure they are ALL captured
   * 
   * - generate bloated versions that will keep track (then call within them will be mixed up) X
   * 
   * - get the graph
   * - code generation (prototype with std-out, then use annotations)
   * 
   * - 'borrow' a few bits from doubles?
   * 
   * 
   * 
   */
}