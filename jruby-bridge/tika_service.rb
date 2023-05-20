#!/usr/bin/env ruby
# Wrapper for tika_service_jruby. This should be started in its own process.

DAEMON = File.join(File.dirname(__FILE__), 'tika_service_jruby')

require 'drb'

module Tika

  class Service
    DEFAULT_PORT = 44344
    DEFAULT_URI = "druby://localhost:#{DEFAULT_PORT}"
    TIMEOUT = 300    # in 100-ms increments

    # Return command to launch JRuby interpreter
    def self.get_jruby
      # 1. detect system JRuby
      jruby = `which jruby`
      return jruby.chomp if (! jruby.empty?)

      # 2. detect RVM-managed JRuby
      return nil if (`which rvm`).empty?
      jruby = `rvm list`.split("\n").select { |rb| rb.include? 'jruby' }.first
      return nil if (! jruby)

      "rvm #{jruby.strip.split(' ').first} do ruby "
    end

    # Replace current process with JRuby running Tika Service
    def self.exec(port)
      jruby = get_jruby
      Kernel.exec "#{jruby} #{DAEMON} #{port || ''}" if jruby

      $stderr.puts "No JRUBY found!"
      return 1
    end

    def self.start
      return @pid if @pid
      @pid = Process.fork do
        exit(::Tika::Service::exec DEFAULT_PORT)
      end
      Process.detach(@pid)

      connected = false
      TIMEOUT.times do
        begin
          DRb::DRbObject.new_with_uri(DEFAULT_URI).to_s
          connected = true
          break
        rescue DRb::DRbConnError
          sleep 0.1
        end
      end
      raise "Could not connect to #{DEFAULT_URI}" if ! connected
    end

    def self.stop
      service_send(:stop_if_unused)
    end

    # this will return a new Tika DRuby connection
    def self.service_send(method, *args)
      begin
        obj = DRb::DRbObject.new_with_uri(DEFAULT_URI)
        obj.send(method, *args)
        obj
      rescue DRb::DRbConnError => e
        $stderr.puts "Could not connect to #{DEFAULT_URI}"
        raise e
      end
    end

    def self.connect
      service_send(:inc_usage)
    end

    def self.disconnect
      service_send(:dec_usage)
    end

  end
end

# ----------------------------------------------------------------------
# main()
Tika::Service::exec ARGV.first if __FILE__ == $0
