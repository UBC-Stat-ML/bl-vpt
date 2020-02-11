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
import blang.distributions.Generators;
import blang.inits.Arg;
import blang.inits.DesignatedConstructor;
import blang.types.StaticUtils;
import blang.types.internals.RealScalar;
import ca.ubc.stat.blang.StaticJavaUtils;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Optional;
import java.util.Random;
import java.util.function.Supplier;
import org.apache.commons.math3.stat.descriptive.SummaryStatistics;
import org.eclipse.xtext.xbase.lib.IntegerRange;

@SuppressWarnings("all")
public class ToyNormal implements Model, UnivariateModel<RealVar> {
  public static class Builder implements ModelBuilder {
    private boolean fromCommandLine = false;
    
    @Arg
    public Optional<RealVar> mu;
    
    public ToyNormal.Builder setMu(final RealVar mu) {
      // work around typeRef(..) limitation
      Optional<RealVar> $generated__dummy = null;
      this.mu = Optional.of(mu);
      return this;
    }
    
    @Arg
    public Optional<Integer> n;
    
    public ToyNormal.Builder setN(final Integer n) {
      // work around typeRef(..) limitation
      Optional<Integer> $generated__dummy = null;
      this.n = Optional.of(n);
      return this;
    }
    
    @Arg
    public Optional<Double> suffStat;
    
    public ToyNormal.Builder setSuffStat(final Double suffStat) {
      // work around typeRef(..) limitation
      Optional<Double> $generated__dummy = null;
      this.suffStat = Optional.of(suffStat);
      return this;
    }
    
    public ToyNormal build() {
      // For each optional type, either get the value, or evaluate the ?: expression
      RealVar mu;
      if (this.mu != null && this.mu.isPresent()) {
        mu = this.mu.get();
      } else {
        mu = $generated__4();
      }
      final RealVar __mu = mu;
      Integer n;
      if (this.n != null && this.n.isPresent()) {
        n = this.n.get();
      } else {
        n = $generated__5(mu);
      }
      final Integer __n = n;
      Double suffStat;
      if (this.suffStat != null && this.suffStat.isPresent()) {
        suffStat = this.suffStat.get();
      } else {
        suffStat = $generated__6(mu, n);
      }
      final Double __suffStat = suffStat;
      // Build the instance after boxing params
      return new ToyNormal(
        __mu, 
        new ConstantSupplier(__n), 
        new ConstantSupplier(__suffStat)
      );
    }
  }
  
  @DesignatedConstructor
  public static ToyNormal.Builder builderFromCommandLine() {
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
  private final Supplier<Double> $generated__suffStat;
  
  public Double getSuffStat() {
    return $generated__suffStat.get();
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
  private static RealVar $generated__0(final RealVar mu, final Integer n, final Double suffStat) {
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
   * { -0.5 * n * pow(suffStat - mu, 2) }
   */
  private static RealVar $generated__3(final Integer n, final RealVar mu, final Double suffStat) {
    double _pow = Math.pow(((suffStat).doubleValue() - (mu).doubleValue()), 2);
    return new blang.core.RealConstant((((-0.5) * (n).intValue()) * _pow));
  }
  
  public static class $generated__3_class implements Supplier<RealVar> {
    public RealVar get() {
      return $generated__3($generated__n.get(), mu, $generated__suffStat.get());
    }
    
    public String toString() {
      return "{ -0.5 * n * pow(suffStat - mu, 2) }";
    }
    
    private final Supplier<Integer> $generated__n;
    
    private final RealVar mu;
    
    private final Supplier<Double> $generated__suffStat;
    
    public $generated__3_class(final Supplier<Integer> $generated__n, final RealVar mu, final Supplier<Double> $generated__suffStat) {
      this.$generated__n = $generated__n;
      this.mu = mu;
      this.$generated__suffStat = $generated__suffStat;
    }
  }
  
  /**
   * Auxiliary method generated to translate:
   * latentReal
   */
  private static RealVar $generated__4() {
    RealScalar _latentReal = StaticUtils.latentReal();
    return _latentReal;
  }
  
  /**
   * Auxiliary method generated to translate:
   * pow(2, 5) as int - 1
   */
  private static Integer $generated__5(final RealVar mu) {
    double _pow = Math.pow(2, 5);
    int _minus = (((int) _pow) - 1);
    return Integer.valueOf(_minus);
  }
  
  /**
   * Auxiliary method generated to translate:
   * { val stats = new SummaryStatistics val rand = new Random(1) for (i : 0 .. n) stats.addValue(rand.normal(100, 1)) System.out.println(stats.mean) stats.mean }
   */
  private static Double $generated__6(final RealVar mu, final Integer n) {
    double _xblockexpression = (double) 0;
    {
      final SummaryStatistics stats = new SummaryStatistics();
      final Random rand = new Random(1);
      IntegerRange _upTo = new IntegerRange(0, (n).intValue());
      for (final Integer i : _upTo) {
        stats.addValue(Generators.normal(rand, 100, 1));
      }
      System.out.println(stats.getMean());
      _xblockexpression = stats.getMean();
    }
    return Double.valueOf(_xblockexpression);
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
  public ToyNormal(@DeboxedName("mu") final RealVar mu, @Param @DeboxedName("n") final Supplier<Integer> $generated__n, @Param @DeboxedName("suffStat") final Supplier<Double> $generated__suffStat) {
    this.mu = mu;
    this.$generated__n = $generated__n;
    this.$generated__suffStat = $generated__suffStat;
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
          $generated__0(mu, $generated__n.get(), $generated__suffStat.get()), 
          new $generated__1_class(), 
          new $generated__2_class()
        )
        );
    }
    { // Code generated by: | n, mu, suffStat ~ LogPotential({ -0.5 * n * pow(suffStat - mu, 2) })
      // Construction and addition of the factor/model:
      components.add(
        new blang.distributions.LogPotential(
          new $generated__3_class($generated__n, mu, $generated__suffStat)
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
  public static RealDistribution distribution(@Param final Integer n, @Param final Double suffStat) {
    UnivariateModel<RealVar> univariateModel = new ToyNormal(
      new RealDistributionAdaptor.WritableRealVarImpl(), 
      new ConstantSupplier(n), 
      new ConstantSupplier(suffStat)
    );
    Distribution<RealVar> distribution = new DistributionAdaptor(univariateModel);
    return new RealDistributionAdaptor(distribution);
  }
}
