package ptgrad

import blang.runtime.internals.DefaultPostProcessor
import java.io.File
import java.util.Map
import opt.Optimizer
import blang.inits.experiments.tabwriters.TidySerializer


import static blang.inits.experiments.tabwriters.factories.CSV.*

class VariationalPostprocessor extends DefaultPostProcessor {
 
  override run() {
    plotTrace(csvFile(results.resultsFolder, "optimization"))
    plotTrace(csvFile(results.resultsFolder, "optimization-path"), '''facet_grid(«Optimizer::NAME» ~.) +''')
    super.run
  }
  
  def plotTrace(File trace) { plotTrace(trace, "") }
  def plotTrace(File trace, String facetGrid) {
    val baseName = TidySerializer::serializerName(trace)
    val outputFile = new File(trace.parent, baseName + ".pdf")
    callR(null, '''
      require("ggplot2")
      require("dplyr")
      
      data <- read.csv("«trace.absolutePath»")
      
      p <- ggplot(data, aes(x = «Optimizer::ITER», y = «TidySerializer::VALUE»)) +
              geom_point(size = 0.1) + geom_line(alpha = 0.5) + «facetGrid»
              theme_bw() + 
              xlab("Optimization iteration") 
              
      ggsave("«outputFile.absolutePath»")
    ''')
  }

}