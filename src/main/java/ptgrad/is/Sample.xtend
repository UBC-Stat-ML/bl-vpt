package ptgrad.is

import xlinear.DenseMatrix

interface Sample {
  def double weight()
  def double logLikelihood(double beta)
  def DenseMatrix score(double beta)
}