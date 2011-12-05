# Example using svm_toolkit to classify letters,
# using UCI's letter-recognition example.
#
# This example illustrates use of built-in grid search to find 
# the best model, using cross-validation on the number 
# of errors.  Displays a contour map of search results.
#
# Written by Peter Lane, 2011.

require "svm_toolkit"
include SvmToolkit

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
TrainingData = make_problem Dataset[0..200] # for speed, only train on 200 instances
CrossSet = make_problem Dataset[2000..3000]
TestSet = make_problem Dataset[3000..-1]

Costs = [-5, -3, -1, 0, 1, 3, 5, 8, 10, 13, 15].collect {|n| 2**n}
Gammas = [-15, -12, -8, -5, -3, -1, 1, 3, 5, 7, 9].collect {|n| 2**n}

best_model = Svm.cross_validation_search(TrainingData, CrossSet, Costs, Gammas, :show_plot => true)

puts "Test set has #{best_model.evaluate_dataset(TestSet, :evaluator => Evaluator::GeometricMean)}"
best_model.save "best.dat"
