package ptanalysis

import blang.inits.experiments.Experiment
import blang.inits.Arg
import java.util.List
import java.util.LinkedList
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class MultiPriorProto extends Experiment {
  @Arg MCEnergies energies
  
  override run() {
    // focus on chain between 0 and min
    val iter = energies.energies.keySet.iterator
    iter.next
    iter.next
    iter.next
    iter.next
    iter.next
    iter.next
    iter.next
    iter.next
    iter.next
    iter.next
    val beta = iter.next
    println("beta = " + beta)
    
    println(energies.swapAcceptPr(0.0, beta))
//    println(energies.swapAcceptPr(0.0, 1e-5))
//    println(energies.swapAcceptPr(0.0, 1e-6))
//    println(energies.swapAcceptPr(0.0, 1e-7))
    
    // split prior list into nChunks
    
//    {
//      val opt = new GridOptimizer(energies, false, 1)
//      println("area = " + opt.area(0.0, 1.0))
//    }
    
    val postReservoir = new LinkedList(energies.energies.get(beta))
    var priorReservoir = energies.energies.get(0.0)
    val chunkSize = 50
    val stats = new SummaryStatistics
    while (priorReservoir.size > chunkSize) {
      val curPriors = priorReservoir.subList(0, chunkSize)
      priorReservoir = priorReservoir.subList(chunkSize, priorReservoir.size)
      val curPost = postReservoir.pop
      
      var sum = 0.0
      for (curPrior : curPriors) 
        sum += Math.exp(beta * (curPost - curPrior))
      
      val acceptPr = sum / (1.0 + sum)
      
      stats.addValue(acceptPr)
    }
    
    println(stats.mean)
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
  
}