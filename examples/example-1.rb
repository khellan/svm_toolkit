# Example to illustrate construction of a dataset by hand,
# with training and evaluating SVM models.
#

require "svm_toolkit"
include SvmToolkit

puts "Classification with LIBSVM"
puts "--------------------------"
 
# Sample dataset: the 'Play Tennis' dataset 
# from T. Mitchell, Machine Learning (1997)
# --------------------------------------------
# Labels for each instance in the training set
#    1 = Play, 0 = Not
Labels = [0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0]

# Recoding the attribute values into range [0, 1]
Instances = [
  [0.0,1.0,1.0,0.0],
  [0.0,1.0,1.0,1.0],
  [0.5,1.0,1.0,0.0],
  [1.0,0.5,1.0,0.0],
  [1.0,0.0,0.0,0.0],
  [1.0,0.0,0.0,1.0],
  [0.5,0.0,0.0,1.0],
  [0.0,0.5,1.0,0.0],
  [0.0,0.0,0.0,0.0],
  [1.0,0.5,0.0,0.0],
  [0.0,0.5,0.0,1.0],
  [0.5,0.5,1.0,1.0],
  [0.5,1.0,0.0,0.0],
  [1.0,0.5,1.0,1.0]
]

# create some arbitrary train/test split
TrainingSet = Problem.from_array(Instances.slice(0, 10), Labels.slice(0, 10))
TestSet     = Problem.from_array(Instances.slice(10, 4), Labels.slice(10, 4))

# Iterate over each kernel type
Parameter.kernels.each do |kernel|
 
  # -- train model for this kernel type
  params = Parameter.new(
    :svm_type => Parameter::C_SVC, 
    :kernel_type => kernel,
    :cost => 10, 
    :degree => 1,
    :gamma => 100
  )
  model = Svm.svm_train(TrainingSet, params)

  # -- test kernel performance on the training set
  errors = model.evaluate_dataset(TrainingSet, :print_results => true)
  puts "Kernel #{Parameter.kernel_name(kernel)} has #{errors} on the training set"

  # -- test kernel performance on the test set
  errors = model.evaluate_dataset(TestSet, :print_results => true)
  puts "Kernel #{Parameter.kernel_name(kernel)} has #{errors} on the test set"
end

