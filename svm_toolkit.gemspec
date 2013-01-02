
Gem::Specification.new do |s|
  s.name = "svm_toolkit"
  s.platform = Gem::Platform::CURRENT
  s.author = "Peter Lane"
  s.version = "1.0.3"
  s.email = "peter.lane@bcs.org.uk"
  s.homepage = "https://github.com/petercrlane/svm_toolkit"
  s.summary = "A JRuby wrapper around the libsvm library, with additional functionality."
  s.license = "GPL3"
  s.description = <<-END
Support-vector machines are a popular tool in data mining.  This package includes an amended version of the Java implementation of the libsvm library (version 3.11).  Additional methods and examples are provided to support standard training techniques, such as cross-validation, various alternative evaluation methods, such as overall accuracy, precision or recall, and simple visualisations. 
END
  s.files = [
    "LICENSE.txt",
    "README.rdoc", 
    "bin/svm-demo",
    "lib/libsvm.jar",
    "lib/PlotPackage.jar",
    "lib/svm_toolkit.rb", 
    "lib/evaluators.rb",
    "examples/example-1.rb",
    "examples/example-2.rb",
    "examples/example-3.rb",
    "examples/example-4.rb",
    "examples/example-5.rb",
    "examples/australian_scale.txt",
    "examples/letter-recognition.data",
    "examples/weather.csv",
    "tests/tests.rb"
  ]
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files << "README.rdoc"
  s.executables << "svm-demo"
  s.post_install_message = "'svm-demo' should now be available via your jruby path.  If not, add \n#{s.full_gem_path}/bin\n to your path."
end

