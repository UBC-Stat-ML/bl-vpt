package ptanalysis;

import blang.core.ConstantSupplier;
import blang.core.DeboxedName;
import blang.core.Distribution;
import blang.core.DistributionAdaptor;
import blang.core.Model;
import blang.core.ModelBuilder;
import blang.core.ModelComponent;
import blang.core.Param;
import blang.core.RealDistribution;
import blang.core.RealDistributionAdaptor;
import blang.core.RealVar;
import blang.core.UnivariateModel;
import blang.inits.Arg;
import blang.inits.DesignatedConstructor;
import blang.types.StaticUtils;
import blang.types.internals.RealScalar;
import ca.ubc.stat.blang.StaticJavaUtils;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Optional;
import java.util.function.Supplier;
import xlinear.Matrix;

@SuppressWarnings("all")
public class ToyNormalSubsampled implements Model, UnivariateModel<RealVar> {
  public static class Builder implements ModelBuilder {
    private boolean fromCommandLine = false;
    
    @Arg
    public Optional<RealVar> mu;
    
    public ToyNormalSubsampled.Builder setMu(final RealVar mu) {
      // work around typeRef(..) limitation
      Optional<RealVar> $generated__dummy = null;
      this.mu = Optional.of(mu);
      return this;
    }
    
    @Arg
    public Optional<Integer> n;
    
    public ToyNormalSubsampled.Builder setN(final Integer n) {
      // work around typeRef(..) limitation
      Optional<Integer> $generated__dummy = null;
      this.n = Optional.of(n);
      return this;
    }
    
    @Arg
    public Matrix partialSums;
    
    private boolean partialSums_initialized = false;
    
    public ToyNormalSubsampled.Builder setPartialSums(final Matrix partialSums) {
      partialSums_initialized = true;
      this.partialSums = partialSums;
      return this;
    }
    
    public ToyNormalSubsampled build() {
      // For each optional type, either get the value, or evaluate the ?: expression
      RealVar mu;
      if (this.mu != null && this.mu.isPresent()) {
        mu = this.mu.get();
      } else {
        mu = $generated__3();
      }
      final RealVar __mu = mu;
      Integer n;
      if (this.n != null && this.n.isPresent()) {
        n = this.n.get();
      } else {
        n = $generated__4(mu);
      }
      final Integer __n = n;
      if (!fromCommandLine && !partialSums_initialized)
        throw new RuntimeException("Not all fields were set in the builder, e.g. missing partialSums");
      final Matrix __partialSums = partialSums;
      // Build the instance after boxing params
      return new ToyNormalSubsampled(
        __mu, 
        new ConstantSupplier(__n), 
        new ConstantSupplier(__partialSums)
      );
    }
  }
  
  @DesignatedConstructor
  public static ToyNormalSubsampled.Builder builderFromCommandLine() {
    Builder result = new Builder();
    result.fromCommandLine = true;
    return result;
  }
  
  private final RealVar mu;
  
  public RealVar getMu() {
    return mu;
  }
  
  @Param
  private final Supplier<Integer> $generated__n;
  
  public Integer getN() {
    return $generated__n.get();
  }
  
  @Param
  private final Supplier<Matrix> $generated__partialSums;
  
  public Matrix getPartialSums() {
    return $generated__partialSums.get();
  }
  
  /**
   * Utility main method for posterior inference on this model
   */
  public static void main(final String[] arguments) {
    StaticJavaUtils.callRunner(Builder.class, arguments);
  }
  
  /**
   * Auxiliary method generated to translate:
   * mu
   */
  private static RealVar $generated__0(final RealVar mu, final Integer n, final Matrix partialSums) {
    return mu;
  }
  
  /**
   * Auxiliary method generated to translate:
   * 0
   */
  private static RealVar $generated__1() {
    return new blang.core.RealConstant(0);
  }
  
  public static class $generated__1_class implements Supplier<RealVar> {
    public RealVar get() {
      return $generated__1();
    }
    
    public String toString() {
      return "0";
    }
    
    public $generated__1_class() {
      
    }
  }
  
  /**
   * Auxiliary method generated to translate:
   * 10 * 10
   */
  private static RealVar $generated__2() {
    return new blang.core.RealConstant((10 * 10));
  }
  
  public static class $generated__2_class implements Supplier<RealVar> {
    public RealVar get() {
      return $generated__2();
    }
    
    public String toString() {
      return "10 * 10";
    }
    
    public $generated__2_class() {
      
    }
  }
  
  /**
   * Auxiliary method generated to translate:
   * latentReal
   */
  private static RealVar $generated__3() {
    RealScalar _latentReal = StaticUtils.latentReal();
    return _latentReal;
  }
  
  /**
   * Auxiliary method generated to translate:
   * 10
   */
  private static Integer $generated__4(final RealVar mu) {
    return Integer.valueOf(10);
  }
  
  /**
   * Note: the generated code has the following properties used at runtime:
   *   - all arguments are annotated with a BlangVariable annotation
   *   - params additionally have a Param annotation
   *   - the order of the arguments is as follows:
   *     - first, all the random variables in the order they occur in the blang file
   *     - second, all the params in the order they occur in the blang file
   * 
   */
  public ToyNormalSubsampled(@DeboxedName("mu") final RealVar mu, @Param @DeboxedName("n") final Supplier<Integer> $generated__n, @Param @DeboxedName("partialSums") final Supplier<Matrix> $generated__partialSums) {
    this.mu = mu;
    this.$generated__n = $generated__n;
    this.$generated__partialSums = $generated__partialSums;
  }
  
  /**
   * A component can be either a distribution, support constraint, or another model  
   * which recursively defines additional components.
   */
  public Collection<ModelComponent> components() {
    ArrayList<ModelComponent> components = new ArrayList();
    
    { // Code generated by: mu ~ Normal(0, 10 * 10)
      // Construction and addition of the factor/model:
      components.add(
        new blang.distributions.Normal(
          $generated__0(mu, $generated__n.get(), $generated__partialSums.get()), 
          new $generated__1_class(), 
          new $generated__2_class()
        )
        );
    }
    
    return components;
  }
  
  public RealVar realization() {
    return mu;
  }
  
  /**
   * Returns an instance with fixed parameters values and conforming the Distribution interface. 
   * Useful when passing around distributions as parameters, e.g. for Dirichlet Process mixtures. 
   * 
   */
  public static RealDistribution distribution(@Param final Integer n, @Param final Matrix partialSums) {
    UnivariateModel<RealVar> univariateModel = new ToyNormalSubsampled(
      new RealDistributionAdaptor.WritableRealVarImpl(), 
      new ConstantSupplier(n), 
      new ConstantSupplier(partialSums)
    );
    Distribution<RealVar> distribution = new DistributionAdaptor(univariateModel);
    return new RealDistributionAdaptor(distribution);
  }
}
