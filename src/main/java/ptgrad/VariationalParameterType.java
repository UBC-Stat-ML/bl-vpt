package ptgrad;

public enum VariationalParameterType
{
  MEAN, 
  SOFTPLUS_VARIANCE;  // variance of the variational component = log ( 1 + e^(unconstrained parameter) )
  
  public String paramName(String variable) {
    return variable + "_" + this;
  }
}
