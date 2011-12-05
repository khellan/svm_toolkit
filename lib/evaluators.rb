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

# The Evaluator module provides some classes and methods to construct 
# classes for evaluating the performance of a model against a dataset.  
# Different evaluators measure different kinds of performance.  
#
# Evaluators are classes which provide the methods:
# * add_result(actual, prediction), called for every instance during evaluation
# * value, to retrieve a measure of performance
# * better_than?(evaluator), to compare performance between two evaluators
module Evaluator

  # Measures accuracy as the percentage of instances 
  # correctly classified out of all the available instances.
  class OverallAccuracy 
    attr_reader :num_correct

    def initialize
      @num_correct = 0
      @total = 0
    end

    def add_result(actual, prediction)
      @total += 1
      @num_correct += 1 if prediction == actual
    end

    # This object is better than given object, if the 
    # given object is an instance of nil, or the accuracy 
    # is better
    def better_than? other
      other.nil? or self.num_correct > other.num_correct
    end

    # Return the accuracy as a percentage.
    def value
      if @total.zero? 
        0.0
      else
        100.0 * @num_correct / @total
      end
    end

    def to_s
      "Overall accuracy: #{value}%"
    end
  end

  # Computes the geometric mean of performance of the model.
  # The geometric mean is the nth root of the product of the 
  # accuracies for each of the n classes (accuracy being 
  # number correct divided by the number of instances 
  # actually in that class).
  class GeometricMean
    Result = Struct.new(:instances, :correct)

    def initialize
      @results = {}
    end

    def add_result(actual, prediction)
      result = @results.fetch(prediction, Result.new(0, 0))
      result.instances += 1
      result.correct += 1 if actual == prediction
      @results[prediction] = result
    end

    def value
      if @results.empty?
        0.0
      else
        @results.values.inject(1){|a,b| a*b.correct.quo(b.instances)} ** (1.quo(@results.size))
      end
    end

    def better_than? other
      other.nil? or self.value < other.value
    end

    def to_s
      "Geometric mean: #{value}"
    end
  end

  # Constructs an evaluation class for the given label.
  # Stores the precision performance of the model against 
  # the given label.  Precision is the proportion of 
  # correct responses out of all the instances assigned 
  # this label.  A high precision means the model is 
  # mostly correctly when it assigns an instance into this 
  # class.
  def Evaluator.ClassPrecision label
    Class.new do
      @@label = label

      def initialize
        @num_correct = 0
        @num_retrieved = 0
      end

      def add_result(actual, prediction)
        if actual == @@label
          @num_retrieved += 1
          @num_correct += 1 if actual == prediction
        end
      end

      def value
        if @num_retrieved.zero?
          0.0
        else
          @num_correct.quo @num_retrieved
        end
      end

      def better_than? other
        other.nil? or self.value < other.value
      end

      def to_s
        "Precision for label #{@@label}: #{value}"
      end
    end
  end

  # Constructs an evaluation class for the given label.
  # Stores the recall performance of the model against the 
  # given label.  Recall is the proportion of correct 
  # responses out of all the instances with this label.
  # A high recall means that nearly all the actual members 
  # of this class are identified.
  def Evaluator.ClassRecall label
    Class.new do
      @@label = label

      def initialize
        @num_correct = 0
        @num_predicted = 0
      end

      def add_result(actual, prediction)
        if prediction == @@label
          @num_predicted += 1
          @num_correct += 1 if actual == prediction
        end
      end

      def value
        if @num_predicted.zero?
          0.0
        else
          @num_correct.quo @num_predicted
        end
      end

      def better_than? other
        other.nil? or self.value < other.value
      end

      def to_s
        "Recall for label #{@@label}: #{value}"
      end
    end
  end

end
