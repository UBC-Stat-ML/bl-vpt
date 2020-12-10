package ptanalysis

import java.util.Collection
import briefj.BriefIO
import briefj.BriefParallel

class TestCosts {
  
  def static double zenoCost(double beta, int n) {
    if (beta == 0) return 0
    if (beta == 1) return n
    val double L = Annealers::log(beta * n, 2)
    return if (L < 0) 1 else Math::pow(2, Math::ceil(L)) as int - 1
  }
  
  def static double linearCost(double beta, int n) {
    if (beta == 0) return 0
    if (beta == 1) return n
    val int l = Math.floor(beta * n) as int
    return l + 1
  }
  
  def static double constantCost(double beta, int n) {
    return n
  }
  
  def static double cost(Collection<Double> schedule, (Double)=>Double costFct) {
    schedule.map[costFct.apply(it)].reduce[x,y|x+y]
  }
  
  
  
  def static void main(String [] args) {
    
    
    val n = Math::pow(2, 10) as int - 1
    
    // constant 
    {
      val schedule = loadSchedule("/Users/bouchard/w/ptanalysis/results/all/2020-02-11-11-11-08-c4Ff4Wbf.exec/monitoring/annealingParameters.csv")
      println(cost(schedule, [beta | constantCost(beta, n)]))
    }
    
    // linear
    {
      val schedule = loadSchedule("/Users/bouchard/w/ptanalysis/results/all/2020-02-11-11-24-46-gG6yN7gh.exec/monitoring/annealingParameters.csv")
      println(cost(schedule, [beta | linearCost(beta, n)]))
    }
    
    // zeno
    {
      val schedule = loadSchedule("/Users/bouchard/w/ptanalysis/results/all/2020-02-11-11-24-25-w8unA8hh.exec/monitoring/annealingParameters.csv")
      println(cost(schedule, [beta | zenoCost(beta, n)]))
    }
  }
  
  def static loadSchedule(String string) {
    BriefIO::readLines(string).indexCSV.filter[get("isAdapt") == "false"].map[Double::parseDouble(get("value"))].toList
  }
  
}