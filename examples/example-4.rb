# This example illustrates loading a datafile from a CSV file, 
# and display of information available for a model and when 
# predicting a value for a given instance of data.

require "svm_toolkit"
include SvmToolkit

puts "Classification with LIBSVM"
puts "--------------------------"
 
# Sample dataset: the 'Play Tennis' dataset 
# from T. Mitchell, Machine Learning (1997)
# --------------------------------------------
Dataset = Problem.from_file("weather.csv", Problem::Csv)

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
  model = Svm.svm_train(Dataset, params)
  # -- report information on model
  puts "Model has kernel: #{Parameter.kernel_name(model.kernel_type)}, cost #{model.cost}, gamma #{model.gamma}"
  puts "Model has #{model.nSV.to_a.join(",")} support vectors for the #{model.number_classes} classes"
  puts "The instances used as support vectors for training are: #{model.support_vector_indices.join(",")}"

  # -- test kernel performance on the training set
  accuracy = model.evaluate_dataset(Dataset, :print_results => true)
  puts "Kernel #{Parameter.kernel_name(kernel)} has #{accuracy} on the training set"

  Dataset.size.times do |i|
    puts "Instance #{i} is predicted as #{model.predict(Dataset, i)} with value #{model.predict_values(Dataset, i)}"
  end
end

