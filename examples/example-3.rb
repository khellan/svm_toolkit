# Example using svm_toolkit to classify letters,
# using UCI's letter-recognition example.
#
# This example illustrates a grid search to find 
# the best model, using cross-validation on the number 
# of errors.  
#
# (The grid-search technique is now built in to the library.)
#
# Written by Peter Lane, 2011.

require "svm_toolkit"
include SvmToolkit

# For given problem and combination of cost/gamma,
# train and return a model using RBF kernel.
def train_rbf_model(problem, cost, gamma)
  Svm.svm_train(problem, Parameter.new(
    :svm_type => Parameter::C_SVC,
    :kernel_type => Parameter::RBF,
    :cost => cost,
    :gamma => gamma
  ))
end

# load letter-recognition data

# -- given list of strings, first is label, rest are numbers of features
def make_instance strings
  [strings.first.codepoints.first - 65, strings[1..-1].collect{|s| s.to_i / 15.0}]
end

def read_data filename
  data = []
  IO.foreach(filename) do |line|
    data << make_instance(line.split(","))
  end

  return data
end

def make_problem instances
  Problem.from_array(
    instances.collect{|i| i[1]}, 
    instances.collect{|i| i[0]}
  )
end

Dataset = read_data "letter-recognition.data"
puts "Read #{Dataset.size} items"
TrainingData = make_problem Dataset[0..2000]
CrossSet = make_problem Dataset[2000..3000]
TestSet = make_problem Dataset[3000..-1]

Costs = [-5, -3, -1, 0, 1, 3, 5, 8, 10, 13, 15].collect {|n| 2**n}
Gammas = [-15, -12, -8, -5, -3, -1, 1, 3, 5, 7, 9].collect {|n| 2**n}

best_model = nil
lowest_error = nil

Costs.each do |cost|
  Gammas.each do |gamma|
    model = train_rbf_model(TrainingData, cost, gamma)
    result = model.evaluate_dataset(CrossSet)
    if result.better_than? lowest_error
      best_model = model
      lowest_error = result
    end
    puts "Testing: C = #{cost}  G = #{gamma} -> #{result}"
  end
end

puts "Test set errors: #{best_model.evaluate_dataset(TestSet)}"
