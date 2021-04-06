package ptgrad

import blang.inits.Implementations
import java.util.ArrayList
import opt.Objective
import ptgrad.VariationalPT.Antithetics
import ptgrad.is.ChainPair
import xlinear.DenseMatrix
import xlinear.MatrixOperations

import static ptgrad.is.TemperingExpectations.*

import static extension blang.types.ExtensionUtils.*
import static extension xlinear.MatrixExtensions.*
import java.util.Map
import java.util.List
import ptgrad.is.Sample

class TemperingObjective implements Objective {
  val VariationalPT vpt 
  
  new(VariationalPT vpt) { 
    this.vpt = vpt
    moveTo(vpt.parameters.copy) // force initial recompute
  }
  
  var double currentPoint
  var DenseMatrix currentGradient
  var evaluationIndex = 0
  
  override moveTo(DenseMatrix updatedParameter) {
    vpt.parameters.setTo(updatedParameter)
    // recompute statistics
    val pointGradientPair = estimate()
    currentPoint = pointGradientPair.key
    currentGradient = pointGradientPair.value
  }
  
  @Implementations(Rejection, SKL, SqrtHalfSKL, Inef, ApproxRejection) 
  static interface ObjectiveType {
    def Pair<Double,DenseMatrix> compute(ChainPair samples, ChainPair tuningSamples)
  }
  
  static class Rejection implements ObjectiveType {
        
    override compute(ChainPair p, ChainPair tuningSamples) {
      
      // in the following, let T = 1[ acceptRatio > 1 ]
      
      // point
      val expectedUntruncatedRatio = expectedUntruncatedRatio(p).estimate.get(0) // E[ (1 - T) x acceptRatio ]
      val probabilityOfTrunc = probabilityOfTruncation(p).estimate.get(0)        // E[ T ]
      val accept = expectedUntruncatedRatio + probabilityOfTrunc
      val reject = 1.0 - accept
      
      // gradient
      val gradientTerms = new ArrayList<DenseMatrix>(2)
      for (i : 0 ..< 2) {
        val expectedGradient = expectedGradient(p.samples.get(i), p.betas.get(i)).estimate 
        val covar = expectedTruncatedGradient(p, i, expectedGradient).estimate                          
        gradientTerms.add(covar)
      }
      val gradient = -2.0 * (gradientTerms.get(0) + gradientTerms.get(1).transpose)
      
      return reject -> gradient
    }
    
  }
  
  static class ApproxRejection implements ObjectiveType {
        
    override compute(ChainPair p, ChainPair tuningSamples) {
      
      // in the following, let T = 1[ acceptRatio > 1 ]
      
      // point
      val expectedUntruncatedRatio = expectedUntruncatedRatio(p).estimate.get(0) // E[ (1 - T) x acceptRatio ]
      val probabilityOfTrunc = probabilityOfTruncation(p).estimate.get(0)        // E[ T ]
      val accept = expectedUntruncatedRatio + probabilityOfTrunc
      val reject = 1.0 - accept
      
      // gradient
      val gradientTerms = new ArrayList<DenseMatrix>(2)
      
      for (i : 1 .. 1) {
        val expectedGradient = expectedGradient(p.samples.get(i), p.betas.get(i)).estimate 
        val covar = expectedTruncatedGradient(p, i, expectedGradient).estimate                           
        gradientTerms.add(covar)
      }
      
      for (i : 0 .. 0) {
        val expectedGradient = expectedGradient(p.samples.get(1), p.betas.get(0)).estimate 
        val covar = expectedTruncatedCrossGradient(p, expectedGradient).estimate                          
        gradientTerms.add(covar.mul(-1.0) )
      }
      
      val gradient = -2.0 * (gradientTerms.get(0) + gradientTerms.get(1)).transpose
      
      return reject -> gradient
    }
    
  }
  
  static class Inef implements ObjectiveType {
    val Rejection rej = new Rejection
    
    override compute(ChainPair p, ChainPair tuningSamples) {
      val rejObj = rej.compute(p, tuningSamples)
      val r = rejObj.key
      val s = 1.0 - r
      return (r/s) -> (rejObj.value / Math::pow(s, 2))
    }
    
  }
  
  static class SqrtHalfSKL implements ObjectiveType {
    val SKL skl = new SKL
    override compute(ChainPair p, ChainPair tuningSamples) {
      val sklObj = skl.compute(p, tuningSamples)
      val obj = if (sklObj.key <= 0.0) 1e-6 else Math::sqrt(0.5 * sklObj.key)
      return obj -> (sklObj.value / 4.0 / obj)
    }
  }
  
  static class SKL implements ObjectiveType {
    
    override compute(ChainPair p, ChainPair tuningSamples) {
      val objectiveTerms = new ArrayList<Double>(2)
      val gradientTerms = new ArrayList<DenseMatrix>(2)
      
      for (i : 0 ..< 2) {
        val samples = p.samples.get(i)
        val beta = p.betas.get(i)
        val expectedDelta = expectedDelta(samples, p.betas).estimate
        objectiveTerms.add(expectedDelta.doubleValue)
        
        gradientTerms +=
          expectedGradientTimesDelta(samples, beta, p.betas).estimate -
          expectedGradient(samples, beta).estimate * expectedDelta +
          expectedGradientDelta(samples, p.betas).estimate
          
      }
      
      return (objectiveTerms.get(1) - objectiveTerms.get(0)) -> (gradientTerms.get(1) - gradientTerms.get(0))
    }
    
  }
    
  def Pair<Double,DenseMatrix> estimate() {
    
    // keep a detailed log
    val detailedLogs = vpt.results.getTabularWriter("stochastic-gradient-evaluations").child("evaluation", evaluationIndex++)
    
    // burn-in a bit
    val tuningSamples = vpt.initSampleLists
    val nBurn = (vpt.nScansPerGradient * vpt.miniBurnInFraction) as int
    val it = vpt.pt
    for (i : 0 ..< nBurn) {
      moveKernel(nPassesPerScan)
      swapKernel
      vpt.record(tuningSamples)
    }
    
    // samples list
    val samples = vpt.initSampleLists
    
    // record samples 
    val nSamples = vpt.nScansPerGradient - nBurn
    for (i : 0 ..< nSamples) {
      moveKernel(nPassesPerScan)
      swapKernel
      vpt.record(samples)
    }
    
    // compute importance sampling estimators
    var objectiveSum = 0.0
    var gradientSum = MatrixOperations::dense(vpt.parameters.nEntries)
    val betas = vpt.betas()
    for (int c : 0 ..< (nChains - 1)) {
      val beta0 = betas.get(c)
      val beta1 = betas.get(c + 1)
      var pair = new ChainPair(#[beta0, beta1], #[new ArrayList(samples.get(beta0)), new ArrayList(samples.get(beta1))])
      var tuning = new ChainPair(#[beta0, beta1], #[new ArrayList(tuningSamples.get(beta0)), new ArrayList(tuningSamples.get(beta1))])
      
      if (vpt.antithetics == Antithetics.OFF) {}
      else if (vpt.antithetics == Antithetics.IS) {
        
        // do this before
        val antitMain = pair.antitheticSamples
        val antitTuning = tuning.antitheticSamples
        
        addNeighbours(samples, vpt.betas, antitMain, c)
        addNeighbours(tuningSamples, vpt.betas, antitTuning, c)
        
        pair.addInPlace(antitMain)
        tuning.addInPlace(antitTuning)
        
        
      } else if (vpt.antithetics == Antithetics.MCMC) {
        pair = pair.addMCMCAntitheticSamples(vpt.pt.random)
        tuning = tuning.addMCMCAntitheticSamples(vpt.pt.random)
      } else throw new RuntimeException
      
      val term = vpt.objective.compute(pair, tuning)
      detailedLogs.write(
        "chain" -> c,
        "dim" -> -1,
        "value" -> term.key
      )
      val grad = term.value
      for (d : 0 ..< grad.nEntries)
        detailedLogs.write(
          "chain" -> c,
          "dim" -> d,
          "value" -> grad.get(d)
        ) 
      objectiveSum += term.key
      gradientSum += term.value
    }
    
    return objectiveSum -> gradientSum
  }
  
  def addNeighbours(Map<Double, List<Sample>> samples, List<Double> betas, ChainPair pair, int _chain) {
    val maxExpansion = Math::min(_chain, vpt.pt.nChains - _chain - 1) // avoid asymmetric number of chains on either side
    val initialESS = pair.ess
    for (direction : #[1, -1]) // start towards prior; on a normal example indeed seems to work slightly better (562 avg ESS vs 492)
      addNeighbours(samples, betas, pair, _chain, initialESS, direction, maxExpansion) 
  }
  
  def addNeighbours(Map<Double, List<Sample>> samples, List<Double> betas, ChainPair pair, int _chain, double initialESS, int direction, int maxExpansion) {
    if (vpt.relativeESSNeighbourhoodThreshold == 1.0)
      return
    var previousESS = initialESS
    var int current = _chain + direction
    var currentESS = 0.0
    var nExpansions = 0
    while (current >= 0 && current < vpt.pt.nChains && nExpansions < maxExpansion) {
      nExpansions++
      val curBeta = betas.get(current)
      if (!pair.betas.contains(curBeta)) {
        pair.addInPlace(samples.get(curBeta))    
        currentESS = pair.ess
        val gain = (currentESS - previousESS) / initialESS
        if (gain < vpt.relativeESSNeighbourhoodThreshold) { 
          return
        }
        previousESS = currentESS
      }
      current = current + direction
    }
  }
  
  override currentPoint() {
    vpt.parameters 
  }
  
  override evaluate() {
    currentPoint
  }
  
  override gradient() {
    currentGradient
  }
  
  def static DenseMatrix pointwiseProduct(DenseMatrix m1, DenseMatrix m2) {
    checkMatch(m1, m2)
    val copy = MatrixOperations::dense(m1.nRows, m2.nCols)
    for (r : 0 ..< m1.nRows)
      for (c : 0 ..< m1.nCols)
        copy.set(r, c, m1.get(r,c) * m2.get(r,c))
    return copy
  }
  
  def static DenseMatrix pointwiseDivide(DenseMatrix m1, DenseMatrix m2) {
    checkMatch(m1, m2)
    val copy = MatrixOperations::dense(m1.nRows, m2.nCols)
    for (r : 0 ..< m1.nRows)
      for (c : 0 ..< m1.nCols)
        copy.set(r, c, m1.get(r,c) / m2.get(r,c))
    return copy
  }
  
  def static void checkMatch(DenseMatrix m1, DenseMatrix m2) {
    if (m1.nRows !== m2.nRows ||  m1.nCols !== m2.nCols)
      throw new RuntimeException
  }
  
}