package ptgrad

import blang.runtime.internals.DefaultPostProcessor
import java.io.File
import java.util.Map
import opt.Optimizer
import blang.inits.experiments.tabwriters.TidySerializer
import static opt.Optimizer.Files.*
import static opt.Optimizer.Fields.*


import static blang.inits.experiments.tabwriters.factories.CSV.*

class VariationalPostprocessor extends DefaultPostProcessor {
 
  override run() {
    
    for (file : #[optimizationMonitoring, optimizationPath, optimizationGradient])
      plotTrace(csvFile(results.resultsFolder, file.toString))
      
    super.run
  }
  

  def plotTrace(File trace) {
    val baseName = TidySerializer::serializerName(trace)
    val outputFile = new File(trace.parent, baseName + ".pdf")
    callR(null, '''
      require("ggplot2")
      require("dplyr")
      
      data <- read.csv("«trace.absolutePath»")
      
      p <- ggplot(data, aes(x = «iter», y = «TidySerializer::VALUE»)) +
              geom_point(size = 0.1) + geom_line(alpha = 0.5) + 
              facet_grid(«name» ~., scales = "free_y") +
              theme_bw() + 
              xlab("Optimization iteration") 
              
      ggsave("«outputFile.absolutePath»")
    ''')
  }

}