#!/usr/bin/env
#Polyglot provides a registry of file types that can be loaded by
#calling its improved version of ?require?. Each file extension
#that can be handled by a custom loader is registered by calling
#Polyglot.register(?ext?, <class>), and then you can simply
#require ?somefile?, which will find and load ?somefile.ext?
#using your custom loader.
#
#This supports the creation of DSLs having a syntax that is most
#appropriate to their purpose, instead of abusing the Ruby syntax.
#
#Required files are attempted first using the normal Ruby loader,
#and if that fails, Polyglot conducts a search for a file having
#a supported extension.
# http://polyglot.rubyforge.org/

require 'polyglot'

class RubyglotLoader
    def self.load(filename, options = nil, &block)
        File.open(filename) {|file|
            # Load the contents of file as Ruby code:
            # Implement your parser here instead!
            Kernel.eval(file.read)
        }
    end
end
Polyglot.register("rgl", RubyglotLoader)
