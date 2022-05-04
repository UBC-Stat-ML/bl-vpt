package ptgrad

import blang.runtime.internals.DefaultPostProcessor
import java.io.File
import java.util.Map
import opt.Optimizer
import blang.inits.experiments.tabwriters.TidySerializer
import static opt.Optimizer.Files.*
import static opt.Optimizer.Fields.*
import blang.System;

import static blang.inits.experiments.tabwriters.factories.CSV.*
import ptbm.OptPT
import java.util.Optional
import briefj.BriefFiles
import blang.engines.internals.factories.PT.Column

class VariationalPostprocessor extends DefaultPostProcessor {
  
  val static public PATH_PLOTS = "pathPlots"
 
  override run() {
    
    val allChainsSamples = new File(blangExecutionDirectory.get, OptPT::SAMPLES_FOR_ALL_CHAINS)
    if (allChainsSamples.exists) {
      System.out.indentWithTiming("Annealing paths")
      for (samples : BriefFiles.ls(allChainsSamples)) 
        if (samples.name.endsWith(".csv") || samples.name.endsWith(".csv.gz")) {
          val types = TidySerializer::types(samples)
          if (types.containsKey(TidySerializer::VALUE)) {
            val type = types.get(TidySerializer::VALUE)
            // statistics that could make sense for both reals and integers
            if (isRealValued(type)) {
              System.out.println("Postprocessing " + variableName(samples))
              createPlot(
                new PathPlot(samples, types, this),
                results.getFileInResultFolder(PATH_PLOTS)
            )
            }
          }
        }
      System.out.popIndent  
    }
    
    System.out.indentWithTiming("Variational chain")
    for (file : #[optimizationMonitoring, optimizationPath, optimizationGradient])
      plotTrace(csvFile(results.resultsFolder, file.toString))
    plotStdErrs()
    super.run
    System.out.popIndent
    
    diagnosticReferenceChain()

  }
  
  
  static class PathPlot extends GgPlot {
    new(File posteriorSamples, Map<String, Class<?>> types, VariationalPostprocessor processor) {
      super(posteriorSamples, types, processor)
    }
    override ggCommand() {
      val facets = facetString
      return '''
      «removeBurnIn»
      
      
      p <- ggplot(data, aes(x = «TidySerializer::VALUE», colour = «Column.chain», group = «Column.chain»)) +
        geom_density() + «facetString»
        theme_bw() + 
        xlab("«variableName»") +
        ylab("density") +
        ggtitle("Density plot for: «variableName»")
      '''
    }
    override facetVariables() {
      indices(types) => [remove(Column.chain.toString)]
    }
  }
  
  def diagnosticReferenceChain() {
    val childFolder = results.getFileInResultFolder(OptPT::fixedReferencePT)
    if (childFolder.exists) {
      System.out.indentWithTiming("Fixed reference chain")
      this.blangExecutionDirectory = Optional.of(childFolder)
      this.results = this.results.child(OptPT::fixedReferencePT)
      super.run
      System.out.popIndent
    }
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