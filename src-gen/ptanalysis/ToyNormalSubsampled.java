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
import blang.distributions.Normal;
import blang.inits.Arg;
import blang.inits.DesignatedConstructor;
import blang.types.AnnealingParameter;
import blang.types.StaticUtils;
import blang.types.internals.RealScalar;
import ca.ubc.stat.blang.StaticJavaUtils;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Optional;
import java.util.Random;
import java.util.function.Supplier;
import ptanalysis.Annealers;
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
    public Optional<Matrix> partialSums;
    
    public ToyNormalSubsampled.Builder setPartialSums(final Matrix partialSums) {
      // work around typeRef(..) limitation
      Optional<Matrix> $generated__dummy = null;
      this.partialSums = Optional.of(partialSums);
      return this;
    }
    
    @Arg
    public Optional<Boolean> useZeno;
    
    public ToyNormalSubsampled.Builder setUseZeno(final Boolean useZeno) {
      // work around typeRef(..) limitation
      Optional<Boolean> $generated__dummy = null;
      this.useZeno = Optional.of(useZeno);
      return this;
    }
    
    public ToyNormalSubsampled build() {
      // For each optional type, either get the value, or evaluate the ?: expression
      RealVar mu;
      if (this.mu != null && this.mu.isPresent()) {
        mu = this.mu.get();
      } else {
        mu = $generated__5();
      }
      final RealVar __mu = mu;
      Integer n;
      if (this.n != null && this.n.isPresent()) {
        n = this.n.get();
      } else {
        n = $generated__6(mu);
      }
      final Integer __n = n;
      Matrix partialSums;
      if (this.partialSums != null && this.partialSums.isPresent()) {
        partialSums = this.partialSums.get();
      } else {
        partialSums = $generated__7(mu, n);
      }
      final Matrix __partialSums = partialSums;
      Boolean useZeno;
      if (this.useZeno != null && this.useZeno.isPresent()) {
        useZeno = this.useZeno.get();
      } else {
        useZeno = $generated__8(mu, n, partialSums);
      }
      final Boolean __useZeno = useZeno;
      // Build the instance after boxing params
      return new ToyNormalSubsampled(
        __mu, 
        new ConstantSupplier(__n), 
        new ConstantSupplier(__partialSums), 
        new ConstantSupplier(__useZeno)
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
  
  @Param
  private final Supplier<Boolean> $generated__useZeno;
  
  public Boolean getUseZeno() {
    return $generated__useZeno.get();
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
  private static RealVar $generated__0(final RealVar mu, final Integer n, final Matrix partialSums, final Boolean useZeno) {
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
   * 100 * 100
   */
  private static RealVar $generated__2() {
    return new blang.core.RealConstant((100 * 100));
  }
  
  public static class $generated__2_class implements Supplier<RealVar> {
    public RealVar get() {
      return $generated__2();
    }
    
    public String toString() {
      return "100 * 100";
    }
    
    public $generated__2_class() {
      
    }
  }
  
  /**
   * Auxiliary method generated to translate:
   * new AnnealingParameter
   */
  private static AnnealingParameter $generated__3(final RealVar mu, final Integer n, final Matrix partialSums, final Boolean useZeno) {
    AnnealingParameter _annealingParameter = new AnnealingParameter();
    return _annealingParameter;
  }
  
  /**
   * Auxiliary method generated to translate:
   * { if (useZeno) Annealers::zeno(mu, beta, partialSums, n) else Annealers::linear(mu, beta, partialSums, n) }
   */
  private static RealVar $generated__4(final Boolean useZeno, final Integer n, final RealVar mu, final Matrix partialSums, final AnnealingParameter beta) {
    double _xifexpression = (double) 0;
    if ((useZeno).booleanValue()) {
      _xifexpression = Annealers.zeno((mu).doubleValue(), beta, partialSums, (n).intValue());
    } else {
      _xifexpression = Annealers.linear((mu).doubleValue(), beta, partialSums, (n).intValue());
    }
    return new blang.core.RealConstant(_xifexpression);
  }
  
  public static class $generated__4_class implements Supplier<RealVar> {
    public RealVar get() {
      return $generated__4($generated__useZeno.get(), $generated__n.get(), mu, $generated__partialSums.get(), beta);
    }
    
    public String toString() {
      return "{ if (useZeno) Annealers::zeno(mu, beta, partialSums, n) else Annealers::linear(mu, beta, partialSums, n) }";
    }
    
    private final Supplier<Boolean> $generated__useZeno;
    
    private final Supplier<Integer> $generated__n;
    
    private final RealVar mu;
    
    private final Supplier<Matrix> $generated__partialSums;
    
    private final AnnealingParameter beta;
    
    public $generated__4_class(final Supplier<Boolean> $generated__useZeno, final Supplier<Integer> $generated__n, final RealVar mu, final Supplier<Matrix> $generated__partialSums, final AnnealingParameter beta) {
      this.$generated__useZeno = $generated__useZeno;
      this.$generated__n = $generated__n;
      this.mu = mu;
      this.$generated__partialSums = $generated__partialSums;
      this.beta = beta;
    }
  }
  
  /**
   * Auxiliary method generated to translate:
   * latentReal
   */
  private static RealVar $generated__5() {
    RealScalar _latentReal = StaticUtils.latentReal();
    return _latentReal;
  }
  
  /**
   * Auxiliary method generated to translate:
   * pow(2, 10) as int - 1
   */
  private static Integer $generated__6(final RealVar mu) {
    double _pow = Math.pow(2, 10);
    int _minus = (((int) _pow) - 1);
    return Integer.valueOf(_minus);
  }
  
  /**
   * Auxiliary method generated to translate:
   * Annealers::generatePartialSums(new Random(1), n, Normal::distribution(1000,1))
   */
  private static Matrix $generated__7(final RealVar mu, final Integer n) {
    Random _random = new Random(1);
    Matrix _generatePartialSums = Annealers.generatePartialSums(_random, (n).intValue(), Normal.distribution(new blang.core.RealConstant(1000), new blang.core.RealConstant(1)));
    return _generatePartialSums;
  }
  
  /**
   * Auxiliary method generated to translate:
   * true
   */
  private static Boolean $generated__8(final RealVar mu, final Integer n, final Matrix partialSums) {
    return Boolean.valueOf(true);
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
  public ToyNormalSubsampled(@DeboxedName("mu") final RealVar mu, @Param @DeboxedName("n") final Supplier<Integer> $generated__n, @Param @DeboxedName("partialSums") final Supplier<Matrix> $generated__partialSums, @Param @DeboxedName("useZeno") final Supplier<Boolean> $generated__useZeno) {
    this.mu = mu;
    this.$generated__n = $generated__n;
    this.$generated__partialSums = $generated__partialSums;
    this.$generated__useZeno = $generated__useZeno;
  }
  
  /**
   * A component can be either a distribution, support constraint, or another model  
   * which recursively defines additional components.
   */
  public Collection<ModelComponent> components() {
    ArrayList<ModelComponent> components = new ArrayList();
    
    { // Code generated by: mu ~ Normal(0, 100 * 100)
      // Construction and addition of the factor/model:
      components.add(
        new blang.distributions.Normal(
          $generated__0(mu, $generated__n.get(), $generated__partialSums.get(), $generated__useZeno.get()), 
          new $generated__1_class(), 
          new $generated__2_class()
        )
        );
    }
    { // Code generated by: | useZeno, n, mu, partialSums, AnnealingParameter beta = new AnnealingParameter ~ LogPotential({ if (useZeno) Annealers::zeno(mu, beta, partialSums, n) else Annealers::linear(mu, beta, partialSums, n) })
      // Required initialization:
      AnnealingParameter beta = $generated__3(mu, $generated__n.get(), $generated__partialSums.get(), $generated__useZeno.get());
      // Construction and addition of the factor/model:
      components.add(
        new blang.distributions.LogPotential(
          new $generated__4_class($generated__useZeno, $generated__n, mu, $generated__partialSums, beta)
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
  public static RealDistribution distribution(@Param final Integer n, @Param final Matrix partialSums, @Param final Boolean useZeno) {
    UnivariateModel<RealVar> univariateModel = new ToyNormalSubsampled(
      new RealDistributionAdaptor.WritableRealVarImpl(), 
      new ConstantSupplier(n), 
      new ConstantSupplier(partialSums), 
      new ConstantSupplier(useZeno)
    );
    Distribution<RealVar> distribution = new DistributionAdaptor(univariateModel);
    return new RealDistributionAdaptor(distribution);
  }
}
