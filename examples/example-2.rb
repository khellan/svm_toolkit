# Example to illustrate reading a dataset from file
#

require "svm_toolkit"
include SvmToolkit

Dataset = Problem.from_file("australian_scale.txt")
puts "Number of instances #{Dataset.size}"

model = Svm.svm_train(Dataset, Parameter.new(
  :svm_type => Parameter::C_SVC, 
  :kernel_type => Parameter::RBF,
  :cost => 1,
  :gamma => 4
))

performance = model.evaluate_dataset(Dataset, :evaluator => Evaluator::OverallAccuracy)
puts performance
performance = model.evaluate_dataset(Dataset, :evaluator => Evaluator::ClassPrecision(-1))
puts performance
performance = model.evaluate_dataset(Dataset, :evaluator => Evaluator::ClassRecall(-1))
puts performance
performance = model.evaluate_dataset(Dataset, :evaluator => Evaluator::ClassPrecision(1))
puts performance
performance = model.evaluate_dataset(Dataset, :evaluator => Evaluator::ClassRecall(1))
puts performance
