package transports

//import blang.engines.internals.factories.PT
//import java.util.List
//import transports.Sinkhorn.Product
//import briefj.BriefLog

class TransportPT { //extends PT {
//  
//  override swapKernel() {
//    if (reversible) throw new RuntimeException
//    swapIndicators = newBooleanArrayOfSize(nChains)
//    val indices = swappingIndices
//    
//    // compute prs
//    val prs = newDoubleArrayOfSize(indices.size)
//    for (k : 0 ..< prs.length) 
//      prs.set(k, swapAcceptPr(indices.get(k)))  NNOOO! there are not bernoulli prs
//      
//    // solve transport
//    val productTarget = new Product(prs)
//    val sink = new Sinkhorn(productTarget.pi, productTarget.costs, 10.0, 100)
//    sink.checkMarginals
//    BriefLog::warnOnce("TODO: optimize the transport code")
//    
//    // perform move
//    sink.
//    
//    // record speed-up
//    
//    
//    return swapIndicators
//  }
//  
//  def List<Integer> swappingIndices() {
//    val offset = swapIndex++ % 2 
//    return (0 ..< (nChains - offset)/2).map[offset + 2 * swapIndex].toList
//  }

}