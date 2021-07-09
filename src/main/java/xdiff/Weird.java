package xdiff;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;

import com.google.common.base.Stopwatch;

import bayonet.distributions.Random;

public class Weird
{
  static List bh = new ArrayList<>();
  
  public static void main(String [] args) {
    Random rand = new Random(1);
    List<Double> data = new ArrayList();
    
    for (int i = 0; i < 100000; i++)
      data.add(rand.nextDouble());
//    bench(1000, () -> {
//      double x = test(data.size(), 2.0, data);
//      bh.add(x);
//    });
    bench(1000, () -> {
      double x = test2(data.size(), 2.0, data);
      bh.add(x);
    });
    System.out.println(bh.get(0));
  }
  
  public static double bench(int nRep, Runnable r) {
    final SummaryStatistics stats = new SummaryStatistics();
    for (int i = 0; i < nRep; i++) {
      final Stopwatch t = Stopwatch.createStarted();
      r.run();
      t.stop();
      if (i > 0.5 * nRep)  
        stats.addValue(t.elapsed(TimeUnit.MICROSECONDS));
    }
    System.out.println(stats.getMean() + "us +/- " + 1.96 * stats.getStandardDeviation()/Math.sqrt(stats.getN()));
    return stats.getMean();
  }

//   public static double test(int size, double m, List<Double> data) {
//     final double p0 = Math.exp(logPoi(0, m));
//     final double logRenorm = Math.log(1.0 + p0);
//     double result = 1.0 * (logPoi(2, m) + logRenorm * (-1.0));
//     for (int i = 0; i < data.size(); i++) {
//       result = result + data.get(i) * (logPoi(data.get(i), m) + logRenorm * (-1.0));
//     }
//     return result;
//   }
//   
//   public static double logPoi(double realization, double mean) {
//     return realization * Math.log(mean) + mean * (-1.0);
//   }
  
  public static double test2(int size, double m, List<Double> data) {
    final double p0 = Math.exp(logPoi2(0, m));
    final double logRenorm = Math.log(1.0 + p0);
    double result = 1.0 * (logPoi2(2, m) + logRenorm * (-1.0));
    final double logm = Math.log(m);
    for (int i = 0; i < data.size(); i++) {
      result += data.get(i) * (  (data.get(i) * logm + m * (-1.0))  + logRenorm * (-1.0));
    }
    return result;
  }
  
  public static double logPoi2(double realization, double mean) {
    return realization * Math.log(mean) + mean * (-1.0);
  }
}
