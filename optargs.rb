#!/usr/bin/env ruby
## basic optargs example

require 'optparse'
require 'ostruct'

SCRIPT_NAME = File.basename($0)
SCRIPT_DESCR = ""
SCRIPT_VERSION = 1.0

def get_opts( args )
  opts_str = "[-n] [-d db] -[p port] [-s server] [-u user] [-P password]"
  options = OpenStruct.new
  options.host = DEFAULT_HOST
  options.database = DEFAULT_DB
  options.user = DEFAULT_USER
  options.password = DEFAULT_PASSWORD
  options.port = DEFAULT_PORT
  options.nonblocking = false

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{SCRIPT_NAME} #{opts_str}"
    opts.separator SCRIPT_DESCR
    opts.separator "Options:"

    opts.on( "-n", "--non-blocking", 
             "Use non-blocking (asynchronous) DB API" ) do 
      options.nonblocking = true
    end

    opts.on( "-d", "--database name", 
             "Name of database to connect to" ) do |db|
      options.database = db
    end

    opts.on( "-p", "--port ", 
             "Port that DB server is listening on" ) do |p|
      options.port = p
    end

    opts.on( "-s", "--server host", 
             "Hostname or IP of DB server" ) do |s|
      options.host = s
    end

    opts.on( "-u", "--user name", 
             "DB user to connect as" ) do |u|
      options.user = u
    end

    opts.on( "-P", "--password secret", 
             "Password for DB user" ) do |p|
      options.password = p
    end

    opts.on_tail("-h", "--help", "Show this message") do 
      puts opts
      exit 0
    end

    opts.on_tail("-v", "--version", "Show version") do 
      puts "#{SCRIPT_NAME} : #{SCRIPT_DESCR}"
      puts "Version #{SCRIPT_VERSION}"
      exit 0
    end

  end

  opts.parse!(args)

  if args.length < 1
    puts "Missing argument"
    puts opts.banner
    exit 1
  end

  return options
end

# ---------------------------------------------------------------------- 

if __FILE__ == $0 then
  options = get_opts(ARGV)
end
