#!/usr/bin/env ruby
require 'json'
DAT_FILE = File.join(File.dirname(__FILE__), 'radlibs.json')

if __FILE__ == $0
  db = JSON.parse(File.read(DAT_FILE))
  template_idx = Kernel.rand(db['template'].length)

  template = db['template'][template_idx].dup
  db.keys.each do |part_of_speech|
    next if part_of_speech == 'template'
    pat = part_of_speech.upcase
    while template =~ /#{pat}/
      pat_idx = Kernel.rand(db[part_of_speech].length) 
      replacement = db[part_of_speech][pat_idx]
      template.sub!(/#{pat}/, replacement)
      template.sub!(/#{pat}-REPEAT/, replacement) if template =~ /#{pat}-REPEAT/ and template !~ /#{pat}.+#{pat}-REPEAT/
    end
  end
  puts "-----------------------------------------------------------------"
  puts template.sub(/^./,&:upcase)
  puts "-----------------------------------------------------------------"
end
