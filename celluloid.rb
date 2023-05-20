#!/usr/bin/env ruby
# test code for https://github.com/celluloid/celluloid

require 'celluloid'

class Runner
  include Celluloid

  def initialize
    @hello = Actor[:hello]
    @world = Actor[:world]
    run!
  end

 def run
   futures = []
   100.times do
     futures << @hello.future.greet
   end
     futures.each { |future| @world.mailbox << future.value }
 end
end

class MyGroup < Celluloid::SupervisionGroup
  supervise Hello, :as => :hello, :args => ["hello"]
  supervise World, :as => :world, :args => ["world"] 
  supervise Runner
end

MyGroup.run!
