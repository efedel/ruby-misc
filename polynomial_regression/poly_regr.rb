#!/usr/bin/env ruby

require 'matrix'
require "ruby_linear_regression"

DEFAULT_DEGREE=12

=begin in R:
df.shuffled <- df[sample(nrow(df)),]

#define number of folds to use for k-fold cross-validation
K <- 10 

#define degree of polynomials to fit
degree <- 5

#create k equal-sized folds
folds <- cut(seq(1,nrow(df.shuffled)),breaks=K,labels=FALSE)

#create object to hold MSE's of models
mse = matrix(data=NA,nrow=K,ncol=degree)

#Perform K-fold cross validation
for(i in 1:K){
    
    #define training and testing data
    testIndexes <- which(folds==i,arr.ind=TRUE)
    testData <- df.shuffled[testIndexes, ]
    trainData <- df.shuffled[-testIndexes, ]
    
    #use k-fold cv to evaluate models
    for (j in 1:degree){
        fit.train = lm(score ~ poly(hours,j), data=trainData)
        fit.test = predict(fit.train, newdata=testData)
        mse[i,j] = mean((fit.test-testData$score)^2) 
    }
}
#find MSE for each degree 
colMeans(mse)

[1]  9.802397  8.748666  9.601865 10.592569 13.545547

#fit best model
best = lm(score ~ poly(hours,2, raw=T), data=df)
#view summary of best model
summary(best)
...
Coefficients:
...
Score = 54.00526 – .07904*(hours) + .18596*(hours)^2
=end

=begin NOTES
Treat as time-series, i.e. X is 1 ... n and Y is elem[X-1]
  linear-regression: Y ~ poly(X+1, degree)

Polynomial is basically:
  Y1 ~ [ 1, 1, 1, ... ]
  Y2 ~ [ 2, 4, 8, 16, ... ]
  Y3 ~ [ 3, 9, 27, 81, ... ]
  ...

so:
data.length.times do |i|
  x = i + 1
  y = data[i]
  x_arr = (0..degree).map { |exp| (x**exp).to_r }
end
... for every elem Y in data. Then linear regression:

note default degree is n-1
first polynomial is just 0 and therefore discarded
=end

def poly_regr(data, degree=nil)
  degree ||= (data.length - 1)
  x = data.length.times.map { |i| (1..degree).map { |p| ((i+1)**p).to_f } }
  #x = data.length.times.map { |i| (0..degree).map { |p| ((i+1)**p).to_f } }
  #x_data = data.length.times.map { |i| (0..degree).map { |p| ((i+1)**p).to_r } }
  #regress(x, data, degree)
  #mx = Matrix[*x]
  #my = Matrix.column_vector(data)
  #((mx.t * mx).inv * mx.t * my).transpose.to_a[0].map(&:to_f)

  linear_regression = RubyLinearRegression.new
  linear_regression.load_training_data(x, data)
  linear_regression.train_normal_equation

  linear_regression.theta.to_a.map { |a| a.shift }
end

def regress(x, y, degree=DEFAULT_DEGREE)
  x_data = x.map { |xi| (0..degree).map { |pow| (xi**pow).to_r } }

  mx = Matrix[*x_data]
  my = Matrix.column_vector(y)

  # FIXME: reverse?
  ((mx.t * mx).inv * mx.t * my).transpose.to_a[0].map(&:to_f)
end


data = 512.times.map { rand 1000 }
puts poly_regr(data, 32).inspect


