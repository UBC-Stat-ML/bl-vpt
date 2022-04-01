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
      
    plotStdErrs()
      
    super.run
  }
  
  def void plotStdErrs() {
    val trace = csvFile(results.resultsFolder, optimization.toString)
    if (trace === null) return
    val baseName = TidySerializer::serializerName(trace)
    val outputFile = new File(results.resultsFolder, "standardErrors.pdf")
    callR(new File(results.resultsFolder, "." + baseName + ".r"), '''
      require("ggplot2")
      require("dplyr")
      
      data <- read.csv("«trace.absolutePath»")
      
      p <- ggplot(data, aes(x = «iter», y = «stderr»)) +
              geom_point(size = 0.1) + geom_line(alpha = 0.5) + 
              theme_bw() + 
              xlab("Optimization iteration") 
                    
      ggsave("«outputFile.absolutePath»")
    ''')
  }

  def plotTrace(File trace) {
    if (trace === null) return
    val baseName = TidySerializer::serializerName(trace)
    val outputFile = new File(trace.parent, baseName + ".pdf")
    callR(new File(results.resultsFolder, "." + baseName + ".r"), '''
      require("ggplot2")
      require("dplyr")
      
      data <- read.csv("«trace.absolutePath»")
      
      verticalSize <- «facetHeight» * length(unique(data$«name»)) 
      horizontalSize <- «facetWidth»
            
      
      p <- ggplot(data, aes(x = «budget», y = «TidySerializer::VALUE»)) +
              geom_point(size = 0.1) + geom_line(alpha = 0.5) + 
              facet_grid(«name» ~., scales = "free_y") +
              theme_bw() + 
              xlab("Optimization budget") 
              
      ggsave("«outputFile.absolutePath»", limitsize = F, height = verticalSize, width = horizontalSize)
    ''')
  }

}