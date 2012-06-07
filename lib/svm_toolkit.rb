# This file is part of svm_toolkit.
#
# Author::    Peter Lane
# Copyright:: Copyright 2011, Peter Lane.
# License::   GPLv3
#
# svm_toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# svm_toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with svm_toolkit.  If not, see <http://www.gnu.org/licenses/>.

require "java"
require "libsvm"
require "PlotPackage"

require "evaluators"

module SvmToolkit

  java_import "libsvm.Parameter"
  java_import "libsvm.Model"
  java_import "libsvm.Problem"
  java_import "libsvm.Node"
  java_import "libsvm.Svm"

  java_import "jahuwaldt.plot.ContourPlot"
  java_import "jahuwaldt.plot.DiamondSymbol"
  java_import "jahuwaldt.plot.PlotDatum"
  java_import "jahuwaldt.plot.PlotPanel"
  java_import "jahuwaldt.plot.PlotRun"

  #
  # Parameter holds values determining the kernel type 
  # and training process.
  #
  class Parameter

    # :attr_accessor: svm_type
    # The type of SVM problem being solved.
    # * C_SVC, the usual classification task.
    # * NU_SVC
    # * ONE_CLASS
    # * EPSILON_SVR
    # * NU_SVR

    # :attr_accessor: kernel_type
    # The type of kernel to use.
    # * LINEAR
    # * POLY
    # * RBF
    # * SIGMOID
    # * PRECOMPUTED

    # :attr_writer: degree
    # A parameter in polynomial kernels.

    # :attr_accessor: gamma
    # A parameter in poly/rbf/sigmoid kernels.

    # :attr_accessor: coef0
    # A parameter for poly/sigmoid kernels.

    # :attr_accessor: cache_size
    # For training, in MB.

    # :attr_accessor: eps
    # For training, stopping criterion.

    # :attr_accessor: C
    # For training with C_SVC, EPSILON_SVR, NU_SVR: the cost parameter.

    # :attr_accessor: nr_weight
    # For training with C_SVC.

    # :attr_accessor: weight_label
    # For training with C_SVC.

    # :attr_accessor: weight
    # For training with C_SVC.

    # :attr_accessor: nu
    # For training with NU_SVR, ONE_CLASS, NU_SVC.

    # :attr_accessor: p
    # For training with EPSILON_SVR.

    # :attr_accessor: shrinking
    # For training, whether to use shrinking heuristics.

    # :attr_accessor: probability
    # For training, whether to use probability estimates.

    # Constructor sets up values of attributes based on provided map.
    # Valid keys with their default values:
    # * :svm_type = Parameter::C_SVC, for the type of SVM
    # * :kernel_type = Parameter::LINEAR, for the type of kernel
    # * :cost = 1.0, for the cost or C parameter
    # * :gamma = 0.0, for the gamma parameter in kernel
    # * :degree = 1, for polynomial kernel
    # * :coef0 = 0.0, for polynomial/sigmoid kernels
    # * :eps = 0.001, for stopping criterion
    # * :nr_weight = 0, for C_SVC
    # * :nu = 0.5, used for NU_SVC, ONE_CLASS and NU_SVR. Nu must be in (0,1]
    # * :p = 0.1, used for EPSILON_SVR
    # * :shrinking = 1, use the shrinking heuristics
    # * :probability = 0, use the probability estimates
    def initialize args
      super()
      self.svm_type    = args.fetch(:svm_type, Parameter::C_SVC)
      self.kernel_type = args.fetch(:kernel_type, Parameter::LINEAR)
      self.C           = args.fetch(:cost, 1.0)
      self.gamma       = args.fetch(:gamma, 0.0)
      self.degree      = args.fetch(:degree, 1)
      self.coef0       = args.fetch(:coef0, 0.0)
      self.eps         = args.fetch(:eps, 0.001)
      self.nr_weight   = args.fetch(:nr_weight, 0)
      self.nu          = args.fetch(:nu, 0.5)
      self.p           = args.fetch(:p, 0.1)
      self.shrinking   = args.fetch(:shrinking, 1)
      self.probability = args.fetch(:probability, 0)

      unless self.nu > 0.0 and self.nu <= 1.0
        raise ArgumentError "Invalid value of nu #{self.nu}, should be in (0,1]"
      end
    end

    # A more readable accessor for the C parameter
    def cost
      self.C
    end

    # A more readable mutator for the C parameter
    def cost= val
      self.C = val
    end

    # Return a list of the available kernels.
    def self.kernels
      [Parameter::LINEAR, Parameter::POLY, Parameter::RBF, Parameter::SIGMOID]
    end

    # Return a printable name for the given kernel.
    def self.kernel_name kernel
      case kernel
      when Parameter::LINEAR
        "Linear"
      when Parameter::POLY
        "Polynomial"
      when Parameter::RBF
        "Radial basis function"
      when Parameter::SIGMOID
        "Sigmoid"
      else
        "Unknown"
      end
    end
  end

  #
  # Node is used to store the index/value pair for an individual 
  # feature of an instance.
  #
  class Node

    # :attr_accessor: index
    # Index of this node in feature set.

    # :attr_accessor: value
    # Value of this node in feature set.

    #
    def initialize(index, value)
      super()
      self.index = index
      self.value = value
    end
  end

  class Model
    # Evaluate model on given data set (an instance of Problem), 
    # returning the number of errors made.
    # Optional parameters include:
    # * :evaluator => Evaluator::OverallAccuracy, the name of the class to use for computing performance
    # * :print_results => false, whether to print the result for each instance
    def evaluate_dataset(data, params = {})
      evaluator = params.fetch(:evaluator, Evaluator::OverallAccuracy)
      print_results = params.fetch(:print_results, false)
      performance = evaluator.new
      data.l.times do |i|
        pred = Svm.svm_predict(self, data.x[i])
        performance.add_result(data.y[i], pred)
        if print_results
          puts "Instance #{i}, Prediction: #{pred}, True label: #{data.y[i]}"
        end
      end
      return performance
    end

    # Return the value of w squared for the hyperplane.
    # -- returned as an array if there is not just one value.
    def w_squared
      if self.w_2.size == 1
        self.w_2[0]
      else
        self.w_2.to_a
      end
    end

    # Return an array of indices of the training instances used as 
    # support vectors.
    def support_vector_indices
      result = []
      unless sv_indices.nil?
        sv_indices.size.times do |i|
          result << sv_indices[i]
        end
      end

      return result
    end

    # Return the SVM problem type for this model
    def svm_type
      self.param.svm_type
    end

    # Return the kernel type for this model
    def kernel_type
      self.param.kernel_type
    end

    # Return the value of the degree parameter
    def degree
      self.param.degree
    end

    # Return the value of the gamma parameter
    def gamma
      self.param.gamma
    end

    # Return the value of the cost parameter
    def cost
      self.param.cost
    end

    # Return the number of classes handled by this model.
    def number_classes
      self.nr_class
    end

    # Save model to given filename.
    # Raises IOError on any error.
    def save filename
      begin
        Svm.svm_save_model(filename, self)
      rescue java.io.IOException
        raise IOError.new "Error in saving SVM model to file"
      end
    end

    # Load model from given filename.
    # Raises IOError on any error.
    def self.load filename
      begin
        Svm.svm_load_model(filename)
      rescue java.io.IOException
        raise IOError.new "Error in loading SVM model from file"
      end
    end

    #
    # Predict the class of given instance number in given problem.
    #
    def predict(problem, instance_number)
      Svm.svm_predict(self, problem.x[instance_number])
    end

    #
    # Return the values of given instance number of given problem against 
    # each decision boundary.
    # (This is the distance of the instance from each boundary.)
    #
    # Return value is an array if more than one decision boundary.
    #
    def predict_values(problem, instance_number)
      dist = Array.new(number_classes*(number_classes-1)/2, 0).to_java(:double)
      Svm.svm_predict_values(self, problem.x[instance_number], dist)
      if dist.size == 1
        return dist[0]
      else
        return dist.to_a
      end
    end
  end

  class Problem

    #
    # Support constructing a problem from arrays of double values.
    # * Input
    #   [+instances+] an array of instances, each instance being an array of doubles.
    #   [+labels+] an array of doubles, forming the labels for each instance.
    #
    # An ArgumentError exception is raised if all the following conditions are not met:
    # * the number of instances should equal the number of labels,
    # * there must be at least one instance, and
    # * every instance must have the same number of features.
    #
    def self.from_array(instances, labels)
      unless instances.size == labels.size
        raise ArgumentError.new "Number of instances must equal number of labels"
      end
      unless instances.size > 0
        raise ArgumentError.new "There must be at least one instance."
      end
      unless instances.collect {|i| i.size}.min == instances.collect {|i| i.size}.max
        raise ArgumentError.new "All instances must have the same size"
      end

      problem = Problem.new
      problem.l = labels.size
      # -- add in the training data
      problem.x = Node[instances.size, instances[0].size].new
      instances.each_with_index do |instance, i|
        instance.each_with_index do |v, j|
          problem.x[i][j] = Node.new(j, v)
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    # To select SvmLight input file format
    SvmLight = 0

    # To select Csv input file format
    Csv = 1

    # To select ARFF input file format
    Arff = 2

    #
    # Read in a problem definition from a file. 
    # Input:
    # * +filename+, the name of the file
    # * +format+, either Svm::SvmLight (default), Svm::Csv or Svm::Arff
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file(filename, format = SvmLight)
      case format 
      when SvmLight
        return self.from_file_svmlight filename
      when Csv
        return self.from_file_csv filename
      when Arff
        return self.from_file_arff filename
      end
    end

    #
    # Read in a problem definition in svmlight format from given 
    # filename.
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file_svmlight filename
      instances = []
      labels = []
      max_index = 0
      IO.foreach(filename) do |line|
        tokens = line.split(" ")
        labels << tokens[0].to_f
        instance = []
        tokens[1..-1].each do |feature|
          index, value = feature.split(":")
          instance << Node.new(index.to_i, value.to_f)
          max_index = [index.to_i, max_index].max 
        end
        instances << instance
      end
      max_index += 1 # to allow for 0 position
      unless instances.size == labels.size
        raise ArgumentError.new "Number of labels read differs from number of instances"
      end
      # now create a Problem definition
      problem = Problem.new
      problem.l = instances.size
      # -- add in the training data
      problem.x = Node[instances.size, max_index].new
      # -- fill with blank nodes
      instances.size.times do |i|
        max_index.times do |j|
          problem.x[i][j] = Node.new(i, 0)
        end
      end
      # -- add known values
      instances.each_with_index do |instance, i|
        instance.each do |node|
          problem.x[i][node.index] = node
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    #
    # Read in a problem definition in csv format from given 
    # filename.
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file_csv filename
      instances = []
      labels = []
      max_index = 0
      IO.foreach(filename) do |line|
        tokens = line.split(",")
        labels << tokens[0].to_f
        instance = []
        tokens[1..-1].each_with_index do |value, index|
          instance << Node.new(index, value.to_f)
        end
        max_index = [tokens.size, max_index].max 
        instances << instance
      end
      max_index += 1 # to allow for 0 position
      unless instances.size == labels.size
        raise ArgumentError.new "Number of labels read differs from number of instances"
      end
      # now create a Problem definition
      problem = Problem.new
      problem.l = instances.size
      # -- add in the training data
      problem.x = Node[instances.size, max_index].new
      # -- fill with blank nodes
      instances.size.times do |i|
        max_index.times do |j|
          problem.x[i][j] = Node.new(i, 0)
        end
      end
      # -- add known values
      instances.each_with_index do |instance, i|
        instance.each do |node|
          problem.x[i][node.index] = node
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    #
    # Read in a problem definition in arff format from given 
    # filename.
    # Assumes all values are numbers (non-numbers converted to 0.0), 
    # and that the class is the last field.
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file_arff filename
      instances = []
      labels = []
      max_index = 0
      found_data = false
      IO.foreach(filename) do |line|
        unless found_data
          puts "Ignoring", line
          found_data = line.downcase.strip == "@data"
          next # repeat the loop
        end
        tokens = line.split(",")
        labels << tokens.last.to_f
        instance = []
        tokens[1...-1].each_with_index do |value, index|
          instance << Node.new(index, value.to_f)
        end
        max_index = [tokens.size, max_index].max 
        instances << instance
      end
      max_index += 1 # to allow for 0 position
      unless instances.size == labels.size
        raise ArgumentError.new "Number of labels read differs from number of instances"
      end
      # now create a Problem definition
      problem = Problem.new
      problem.l = instances.size
      # -- add in the training data
      problem.x = Node[instances.size, max_index].new
      # -- fill with blank nodes
      instances.size.times do |i|
        max_index.times do |j|
          problem.x[i][j] = Node.new(i, 0)
        end
      end
      # -- add known values
      instances.each_with_index do |instance, i|
        instance.each do |node|
          problem.x[i][node.index] = node
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    # Return the number of instances
    def size
      self.l
    end

    # Rescale values within problem to be in range min_value to max_value
    #
    # For SVM models, it is recommended all features be in range [0,1] or [-1,1]
    def rescale(min_value = 0.0, max_value = 1.0)
      return if self.l.zero?
      x[0].size.times do |i|
        rescale_column(i, min_value, max_value)
      end
    end

    # Create a new problem by combining the instances in this problem with 
    # those in the given problem.
    def merge problem
      unless self.x[0].size == problem.x[0].size
        raise ArgumentError.new "Cannot merge two problems with different numbers of features"
      end
      num_features = self.x[0].size
      num_instances = size + problem.size

      new_problem = Problem.new
      new_problem.l = num_instances
      new_problem.x = Node[num_instances, num_features].new
      new_problem.y = Java::double[num_instances].new
      # fill out the features
      num_instances.times do |i|
        num_features.times do |j|
          if i < size
            new_problem.x[i][j] = self.x[i][j]
          else
            new_problem.x[i][j] = problem.x[i-size][j]
          end
        end
      end
      # fill out the labels
      num_instances.times do |i|
        if i < size
          new_problem.y[i] = self.y[i]
        else
          new_problem.y[i] = problem.y[i-size]
        end
      end

      return new_problem
    end

    # Rescale values within problem for given column index, 
    # to be in range min_value to max_value
    private
    def rescale_column(col, min_value, max_value)
      # -- first locate the column's range
      current_min = x[0][col].value
      current_max = x[0][col].value
      self.l.times do |index|
        if x[index][col].value < current_min
          current_min = x[index][col].value
        end
        if x[index][col].value > current_max
          current_max = x[index][col].value
        end
      end
      # -- then update each value
      self.l.times do |index|
        x[index][col].value = ((max_value - min_value) * (x[index][col].value - current_min) / (current_max - current_min)) + min_value
      end
    end
  end

  class Svm

    #
    # :singleton-method: svm_train
    # 
    # * Input
    #   [+problem+] instance of Problem
    #   [+param+]   instance of Parameter
    # 
    # * Output
    #   [+model+] instance of Model

    #
    # :singleton-method: svm_cross_validation
    #
    # * Input
    #   [+problem+] instance of Problem
    #   [+param+]   instance of Parameter
    #   [+nr_fold+] number of folds
    #   [+target+]
    #

    #
    # Perform cross validation search on given gamma/cost values, 
    # using an RBF kernel, 
    # returning the best performing model and optionally displaying 
    # a contour map of performance.
    #
    # * Input
    #   [+training_set+]   instance of Problem, used for training
    #   [+cross_valn_set+] instance of Problem, used for evaluating models
    #   [+costs+]          array of cost values to search across
    #   [+gammas+]         array of gamma values to search across
    #   [+params+]         Optional parameters include:
    #     * :evaluator => Evaluator::OverallAccuracy, the name of the class 
    #     to use for computing performance
    #     * :show_plot => false, whether to display contour plot
    #     * :train_whole => false, whether to train the final model on both 
    #     the training and cross-validation datasets
    #
    # * Output
    #   [+model+]          instance of Model, the best performing model
    #
    def self.cross_validation_search(training_set, cross_valn_set, 
                                     costs = [-2,-1,0,1,2,3].collect {|i| 2**i}, 
                                     gammas = [-2,-1,0,1,2,3].collect {|i| 2**i}, 
                                     params = {})
      evaluator = params.fetch(:evaluator, Evaluator::OverallAccuracy)
      show_plot = params.fetch(:show_plot, false)
      train_whole = params.fetch(:train_whole, false)
      results = []
      best_model = nil
      lowest_error = nil

      gammas.each do |gamma|
        results_row = []
        costs.each do |cost|
          model = Svm.svm_train(training_set, Parameter.new(
            :svm_type => Parameter::C_SVC,
            :kernel_type => Parameter::RBF,
            :cost => cost,
            :gamma => gamma
          ))
          result = model.evaluate_dataset(cross_valn_set, :evaluator => evaluator)
          if result.better_than? lowest_error
            best_model = model
            lowest_error = result
          end
          puts "Result for cost = #{cost}  gamma = #{gamma} is #{result.value}"
          results_row << result.value
        end
        results << results_row
      end

      if show_plot
        ContourDisplay.new(costs.collect {|n| Math.log2(n)}, 
                           gammas.collect {|n| Math.log2(n)}, 
                           results)
      end

      return best_model
    end

    private
    class ContourDisplay < javax.swing.JFrame
      def initialize(xs, ys, zs)
        super("Cross-Validation Performance")
        self.setSize(500, 400)

        cxs = Java::double[][ys.size].new
        cys = Java::double[][ys.size].new
        ys.size.times do |i|
          cxs[i] = Java::double[xs.size].new
          cys[i] = Java::double[xs.size].new
          xs.size.times do |j|
            cxs[i][j] = xs[j]
            cys[i][j] = ys[i]
          end
        end

        czs = Java::double[][ys.size].new
        ys.size.times do |i|
          czs[i] = Java::double[xs.size].new
          xs.size.times do |j|
            czs[i][j] = zs[i][j]
          end
        end

        plot = ContourPlot.new(
          cxs,
          cys,
          czs,
          10,
          false,
          "",
          "Cost (log-scale)",
          "Gamma (log-scale)",
          nil,
          nil
        )
        plot.colorizeContours(java.awt::Color.green, java.awt::Color.red)

        symbol = DiamondSymbol.new
        symbol.border_color = java.awt::Color.blue
        symbol.fill_color = java.awt::Color.blue
        symbol.size = 4

        run = PlotRun.new
        ys.size.times do |i|
          xs.size.times do |j|
            run.add(PlotDatum.new(cxs[i][j], cys[i][j], false, symbol))
          end
        end

        plot.runs << run

        panel = PlotPanel.new(plot)
        panel.background = java.awt::Color.white
        add panel

        self.setDefaultCloseOperation(javax.swing.WindowConstants::DISPOSE_ON_CLOSE)
        self.visible = true
      end
    end
  end
end

