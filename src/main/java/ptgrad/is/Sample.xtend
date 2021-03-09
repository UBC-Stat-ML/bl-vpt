package ptgrad.is

import xlinear.DenseMatrix

interface Sample {
  def double weight()
  def double logDensity(double beta)
  def DenseMatrix gradient(double beta)
  def Sample importanceSample(double betaPrime)
}