#!/usr/bin/env ruby
# convert SFPM to RPM for various stock diameters

DIAS = [ 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1,
         1.25, 1.5, 1.75, 2, 2.5, 3, 3.5, 4, 4.5, 5, 6, 8, 10, 12 ]
if ARGV.empty?
  puts "Usage: #{$0} SFPM [DIA]"
  exit 1
end

sfpm = Integer(ARGV.shift)
dias = []
ARGV.each { |x| dias << Float(x) }
dias = DIAS if dias.empty?

puts "SFPM #{sfpm}"
dias.each do |dia|
  # SFPM = Wheel Diameter in inches x RPM x 0.262
  # RPM = SFPM / (dia * 0.262)
  rpm = sfpm / (dia * 0.262)
  # RPM = (FPM * 4) / DIA
  rpm = (sfpm * 4) / dia
  # SFM = RPM/3.82(most use 4)x CUT DIA.
  # RPM = SFM x 3.82/Cut DIA.
  rpm = (sfpm * 3.82) / dia
  puts "#{dia} : #{rpm} RPM"
end

