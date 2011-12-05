= svm_toolkit =

Support-vector machines are a popular tool in data mining.  This package
includes an amended version of the Java implementation of the libsvm library
(version 3.11).  Additional methods and examples are provided to support
standard training techniques, such as cross-validation, and simple
visualisations.  Training/testing of models can use a variety of built-in or
user-defined evaluation methods, including overall accuracy, geometric mean,
precision and recall.

= Install =

This software works with JRuby, in 1.9 mode.

To install:

$ jruby -S gem install svm_toolkit

= Features =

== Current ==

. All features of LibSVM 3.11 are supported, and many are augmented with Ruby wrappers.
. Loading Problem definitions from file in Svmlight, Csv or Arff (simple subset) format.
. Creating Problem definitions from values supplied programmatically in arrays.
. Rescaling of feature values.
. Integrated cost/gamma search for model with RBF kernel.
. Contour plot visualisation of cost/gamma search results.
. Model provides value of w-squared for hyperplane.
. svm-demo application, a version of the svm_toy applet which comes with libsvm.
. Model stores indices of training instances used as support vectors.
. User-selected evaluation techniques supported in Model#evaluate_dataset and Svm.cross_validation_search.
. Library provides evaluation classes for OverallAccuracy, GeometricMean, ClassPrecision, ClassRecall.

== Planned ==

. splitting problem sets for train/cross/test
. support for sampling, SMOTE and related processes (perhaps in separate package)
. active-learning
. make grid search use multiple threads.

= License =

svm_toolkit is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

svm_toolkit is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with svm_toolkit.  If not, see <http://www.gnu.org/licenses/>.

Copyright 2011, Peter Lane

= Acknowledgements =

The svm_toolkit is based on LibSVM, which is available from: 
http://www.csie.ntu.edu.tw/~cjlin/libsvm/

The contour plot uses the PlotPackage library, available from:
http://homepage.mac.com/jhuwaldt/java/Packages/Plot/PlotPackage.html

