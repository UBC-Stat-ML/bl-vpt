package transports

import bayonet.math.CoordinatePacker

class Product extends InvarianceTransportProductSpace {
  val double [] prs  // Bernoulli parameters
  
  def n() { prs.length }
  
  new(double [] prs) {
    super({
      val int[] sizes = newIntArrayOfSize(prs.length)
      for (v : 0 ..< prs.length) 
        sizes.set(v, 2)
      new CoordinatePacker(sizes)
    })
    this.prs = prs
  }
  
  def double pr(int p, int [] s) {
    if (s.get(p) === 1) return prs.get(p)
    else if (s.get(p) === 0) return 1.0 - prs.get(p)
    else throw new RuntimeException
  }
  
  override logWeight(int[] s) {
    var it = 1.0
    for (p : 0 ..< n)
      it += Math::log(pr(p, s))
    return it
  }
  
  override cost(int[] s1, int[] s2) {
    StaticUtils::intersectionSize(s1, s2)
  }
}