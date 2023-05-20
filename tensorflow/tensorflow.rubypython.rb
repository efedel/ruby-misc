#!/usr/bin/env ruby

require 'rubypython'

# ----------------------------------------------------------------------
# IGNORE ME
# the now-standard rubypython python-detect fix
class RubyPython::Interpreter                                                   
  alias :find_python_lib_orig :find_python_lib

  def find_python_lib
    @libbase = "#{::FFI::Platform::LIBPREFIX}#{@version_name}"
    @libext = ::FFI::Platform::LIBSUFFIX
    @libname = "#{@libbase}.#{@libext}"

    # python-config --confdir provides location of .so 
    config_util = "#{version_name}-config"
    confdir = %x(#{config_util} --configdir).chomp

    library = File.join(confdir, @libname)
    if (File.exist? library)
      @locations = [ library ]
    else
      library = find_python_lib_orig
    end

    library
  end
end 

# another fix, for modules (like tensorflow) which check argv[0] ans result in:
#   AttributeError: 'module' object has no attribute 'argv'
module RubyPython
  def self.start_with_argv(argv, options={})
    RubyPython.start(options)
    sys = RubyPython.import('sys')
    sys.argv = argv
  end
end

# ----------------------------------------------------------------------

# To use a specific version of python:
#RubyPython.start_with_argv([$0], :python_exe => "/usr/bin/python2.7")
RubyPython.start_with_argv( [$0] )
np = RubyPython.import('numpy')
tf = RubyPython.import('tensorflow')

# FROM HERE ON WE ARE RE-IMPLEMENTING  THE CODE IN
#   https://www.tensorflow.org/versions/r0.11/get_started/index.html
# Create 100 phony x, y data points in NumPy, y = x * 0.1 + 0.3
x_data = np.random.rand(100).astype(np.float32)
y_data = x_data * 0.1 + 0.3

# Try to find values for W and b that compute y_data = W * x_data + b
# (We know that W should be 0.1 and b 0.3, but TensorFlow will
# figure that out for us.)
w = tf.Variable(tf.random_uniform([1], -1.0, 1.0))
b = tf.Variable(tf.zeros([1]))
y = w * x_data + b

# Minimize the mean squared errors.
loss = tf.reduce_mean(tf.square(y - y_data))
optimizer = tf.train.GradientDescentOptimizer(0.5)
train = optimizer.minimize(loss)

# Launch the graph.
s = tf.Session.new()
# Run first with initialized variables.
s.run(tf.initialize_all_variables())

# Fit the line.
201.times do |step|
  s.run(train)
  puts "[#{step}] #{s.run(w)} #{s.run(b)}" if step % 20 == 0
end
