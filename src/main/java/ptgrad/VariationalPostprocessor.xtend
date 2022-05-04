package ptgrad

import blang.runtime.internals.DefaultPostProcessor
import java.io.File
import blang.inits.experiments.tabwriters.TidySerializer
import static opt.Optimizer.Files.*
import static opt.Optimizer.Fields.*
import blang.System;

import static blang.inits.experiments.tabwriters.factories.CSV.*
import ptbm.OptPT
import java.util.Optional
import blang.inits.DefaultValue
import blang.inits.Arg

class VariationalPostprocessor extends DefaultPostProcessor {
  
  public val static String VARIATIONAL_COLOUR = "skyblue1"
  public val static String FIXED_REF_COLOUR = "orange"
  public val static String TARGET_COLOUR = "grey30"
  
  @Arg
  @DefaultValue("scale_colour_gradient(low = \"" + TARGET_COLOUR + "\", high = \"" + FIXED_REF_COLOUR + "\")")
  public String fixedPathPlotArguments = "scale_colour_gradient(low = \"" + TARGET_COLOUR + "\", high = \"" + FIXED_REF_COLOUR + "\")"
  
  @Arg
  @DefaultValue("scale_colour_gradient(low = \"" + TARGET_COLOUR + "\", high = \"" + VARIATIONAL_COLOUR + "\")")
  public String variationalPathPlotArguments = "scale_colour_gradient(low = \"" + TARGET_COLOUR + "\", high = \"" + VARIATIONAL_COLOUR + "\")"
 
  override run() {
    this.pathPlotArguments = fixedPathPlotArguments;
    System.out.indentWithTiming("Variational chain")
    for (file : #[optimizationMonitoring, optimizationPath, optimizationGradient])
      plotTrace(csvFile(results.resultsFolder, file.toString))
    plotStdErrs()
    super.run
    System.out.popIndent
    
    diagnosticReferenceChain()
  }
  
  def diagnosticReferenceChain() {
    val childFolder = results.getFileInResultFolder(OptPT::fixedReferencePT)
    if (childFolder.exists) {
      System.out.indentWithTiming("Fixed reference chain")
      this.blangExecutionDirectory = Optional.of(childFolder)
      this.pathPlotArguments = variationalPathPlotArguments;
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