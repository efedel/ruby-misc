#!/usr/bin/env ruby
# test of FANN
# http://ruby-fann.rubyforge.org/

require 'rubygems'
require 'ruby_fann/neural_network'

# Create Training data with 2 each of inputs(array of 3) & desired outputs(array of 1).
training_data = RubyFann::TrainData.new(
  :inputs=>[[0.3, 0.4, 0.5], [0.1, 0.2, 0.3]], 
  :desired_outputs=>[[0.7], [0.8]])

# Create FANN Neural Network to match appropriate training data:
fann = RubyFann::Standard.new(
  :num_inputs=>3, 
  :hidden_neurons=>[2, 8, 4, 3, 4], 
  :num_outputs=>1)

# Training using data created above:
fann.train_on_data(training_data, 1000, 1, 0.1)

# Run with different input data:
outputs = fann.run([0.7, 0.9, 0.2]) 
