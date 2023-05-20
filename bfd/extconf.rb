#!/usr/bin/env ruby
# extconf.rb for libbfd ruby module

require 'mkmf'

extension_name = 'bfd'

dir_config(extension_name)

create_makefile(extension_name)
