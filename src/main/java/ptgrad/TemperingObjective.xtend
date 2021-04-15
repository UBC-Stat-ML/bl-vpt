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
import java.util.Collection
import java.util.LinkedHashMap
import java.util.Set
import java.util.LinkedHashSet
import java.util.Arrays
import java.util.Collections
import org.eclipse.xtend.lib.annotations.Accessors
import is.DiagonalHalfSpaceImportanceSampler
import static extension java.lang.Math.*
import is.ImportanceSampler

class TemperingObjective implements Objective {
  val VariationalPT vpt 
  
  new(VariationalPT vpt) { 
    this.vpt = vpt
    moveTo(vpt.parameters.copy) // force initial recompute
  }
  
  var double currentPoint
  var DenseMatrix currentGradient
  var Map<String,Double> monitors
  var evaluationIndex = 0
  
  override moveTo(DenseMatrix updatedParameter) {
    vpt.parameters.setTo(updatedParameter)
    // recompute statistics
    val allEstimates = estimate(objectiveTypes)
    val pointGradientPair = allEstimates.get(vpt.objective)
    currentPoint = pointGradientPair.objective
    currentGradient = pointGradientPair.gradient
    
    monitors = new LinkedHashMap(allEstimates.entrySet.filter[it !== vpt.objective].toMap([key.class.simpleName], [value.objective]))
    val ineff = monitors.get(Inef.simpleName)
    monitors.put("RoundTripRate", 1.0 / (2.0 + ineff))
  }
  
  override monitors() {
    return monitors
  }
  
  def Set<ObjectiveType> objectiveTypes() {
    new LinkedHashSet(Arrays.asList(vpt.objective, new Rejection, new Inef))
  }
  
  override description() { vpt.objective.class.simpleName }
  
  @Implementations(Rejection, SKL, SqrtHalfSKL, Inef, ApproxRejection) 
  static interface ObjectiveType {
    def ObjectiveEvaluation compute(ChainPair samples, ChainPair tuningSamples)
  }
  
  static class ObjectiveEvaluation {
    @Accessors(PUBLIC_GETTER) Double objective = null
    @Accessors(PUBLIC_GETTER) DenseMatrix gradient = null
    
    // optional
    Double objectiveVariance = null
    def objectiveStdErr() { return sqrt(objectiveVariance) }
    
    // Note: Not computing gradient std err estimates as the estimates do not take into account control variates

    def +=(ObjectiveEvaluation another) {
      if (this.objective === null) {
        // this takes care of initialization
        this.objective = another.objective
        if (this.gradient !== null) throw new RuntimeException
        this.gradient = another.gradient
        
        this.objectiveVariance = another.objectiveVariance
        //this.gradientVariance = another.gradientVariance
      } else {
        this.objective = this.objective + another.objective 
        this.gradient += another.gradient
        
        if (this.objectiveVariance !== null) {
          this.objectiveVariance = this.objectiveVariance + another.objectiveVariance 
          //this.gradientVariance += another.gradientVariance
        }
      }
      
    }
  }
  
  static class Rejection implements ObjectiveType {
        
    override compute(ChainPair p, ChainPair tuningSamples) {
      
      val result = new ObjectiveEvaluation
            
      // point
      val expectedUntruncatedRatio = expectedUntruncatedRatio(p) 
      val probabilityOfTrunc = probabilityOfTruncation(p)        
      val accept = expectedUntruncatedRatio.estimate.doubleValue + probabilityOfTrunc.estimate.doubleValue
      result.objective = 1.0 - accept
      result.objectiveVariance = expectedUntruncatedRatio.standardError.doubleValue.pow(2) + probabilityOfTrunc.standardError.doubleValue.pow(2)
      
      // gradient
      val gradientTerms = new ArrayList<DiagonalHalfSpaceImportanceSampler<?,?>>(2)
      for (i : 0 ..< 2) {
        val expectedGradient = expectedGradient(p.samples.get(i), p.betas.get(i)).estimate 
        val covar = expectedTruncatedGradient(p, i, expectedGradient)                          
        gradientTerms.add(covar)
      }
      result.gradient = -2.0 * (gradientTerms.get(0).estimate + gradientTerms.get(1).estimate.transpose)
      //result.gradientVariance = 4.0 * (gradientTerms.get(0).standardError.pointwise[pow(2)] + gradientTerms.get(1).standardError.pointwise[pow(2)])
      
      return result
    }
    
  }
  
  static class ApproxRejection implements ObjectiveType {
        
    override compute(ChainPair p, ChainPair tuningSamples) {
      
      val result = new ObjectiveEvaluation
      
      // point
      val expectedUntruncatedRatio = expectedUntruncatedRatio(p)
      val probabilityOfTrunc = probabilityOfTruncation(p)
      val accept = expectedUntruncatedRatio.estimate.doubleValue + probabilityOfTrunc.estimate.doubleValue
      result.objective = 1.0 - accept
      result.objectiveVariance = expectedUntruncatedRatio.standardError.doubleValue.pow(2) + probabilityOfTrunc.standardError.doubleValue.pow(2)
      
      // gradient
      val gradientTerms = new ArrayList<DiagonalHalfSpaceImportanceSampler<?,?>>(2)
      
      for (i : #[1]) {
        val expectedGradient = expectedGradient(p.samples.get(i), p.betas.get(i)).estimate 
        val covar = expectedTruncatedGradient(p, i, expectedGradient)                           
        gradientTerms.add(covar)
      }
      
      for (i : #[0]) {
        val expectedGradient = expectedGradient(p.samples.get(1), p.betas.get(0)).estimate 
        val covar = expectedTruncatedCrossGradient(p, expectedGradient)                          
        gradientTerms.add(covar)
      }
      
      result.gradient = -2.0 * (gradientTerms.get(1).estimate - gradientTerms.get(0).estimate).transpose
      //result.gradientVariance = 4.0 * 
      
      return result
    }
    
  }
  
  static class Inef implements ObjectiveType {
    val Rejection rej = new Rejection
    
    override compute(ChainPair p, ChainPair tuningSamples) {
      val rejObj = rej.compute(p, tuningSamples)
      val r = rejObj.objective
      val s = 1.0 - r
      
      val result = new ObjectiveEvaluation
      result.objective = r/s
      result.gradient = rejObj.gradient / pow(s, 2)
      return result
    }
    
  }
  
  static class SqrtHalfSKL implements ObjectiveType {
    val SKL skl = new SKL
    override compute(ChainPair p, ChainPair tuningSamples) {
      val sklObj = skl.compute(p, tuningSamples)
      
      val result = new ObjectiveEvaluation
      result.objective = if (sklObj.objective <= 1e-6) 1e-6 else Math::sqrt(0.5 * sklObj.objective)
      result.gradient = sklObj.gradient / 4.0 / result.objective
      return result
    }
  }
  
  static class SKL implements ObjectiveType {
    
    override compute(ChainPair p, ChainPair tuningSamples) {
      val result = new ObjectiveEvaluation
      val objectiveTerms = new ArrayList<ImportanceSampler>(2)
      val gradientTerms = new ArrayList<DenseMatrix>(2)
      
      for (i : 0 ..< 2) {
        val samples = p.samples.get(i)
        val beta = p.betas.get(i)
        val expectedDelta = expectedDelta(samples, p.betas)
        objectiveTerms.add(expectedDelta)
        
        gradientTerms +=
          expectedGradientTimesDelta(samples, beta, p.betas).estimate -
          expectedGradient(samples, beta).estimate * expectedDelta.estimate +
          expectedGradientDelta(samples, p.betas).estimate
          
      }
      
      result.objective = objectiveTerms.get(1).estimate.doubleValue - objectiveTerms.get(0).estimate.doubleValue
      result.gradient = gradientTerms.get(1) - gradientTerms.get(0)
      result.objectiveVariance = objectiveTerms.get(1).standardError.doubleValue.pow(2) + objectiveTerms.get(0).standardError.doubleValue.pow(2)
      
      return result
    }
    
  }
  
  def ObjectiveEvaluation estimate() {
    val key = vpt.objective
    return estimate(Collections.singletonList(key)).get(key)
  }
    
  def Map<ObjectiveType,ObjectiveEvaluation> estimate(Collection<ObjectiveType> objectives) {
    
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
    val result = new LinkedHashMap<ObjectiveType,ObjectiveEvaluation>
    for (objectiveType : objectives) {
      val eval = new ObjectiveEvaluation
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
        
        val term = objectiveType.compute(pair, tuning)
        
        if (vpt.detailedGradientInfo) {
          detailedLogs.write(
            "chain" -> c,
            "objectiveType" -> objectiveType.class.simpleName, 
            "dim" -> -1,
            "value" -> term.objective
          )
          val grad = term.gradient
          for (d : 0 ..< grad.nEntries)
            detailedLogs.write(
              "chain" -> c,
              "objectiveType" -> objectiveType.class.simpleName,
              "dim" -> d,
              "value" -> grad.get(d)
            ) 
            
        }
          
        eval += term
      }
      
      result.put(objectiveType, eval)
    }
    
    return result
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