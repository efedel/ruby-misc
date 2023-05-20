#!/usr/bin/env ruby
# code to convert Physiobank format-212 to tab-delimited output

=begin
Each sample is represented by a 12-bit two's complement amplitude. The first sample is obtained from the 12 least significant bits of the first byte pair (stored least significant byte first). The second sample is formed from the 4 remaining bits of the first byte pair (which are the 4 high bits of the 12-bit sample) and the next byte (which contains the remaining 8 bits of the second sample). The process is repeated for each successive pair of samples. Most of the signal files in PhysioBank are written in format 212. 
=end

=begin rdoc
plot in gnuplot using
   plot '/tmp/a.dat' using 1:2 title 'lead 1' with lines, '/tmp/a.dat' using 1:3 title 'lead 2' with lines
OR
   plot '< head -1024 /tmp/a.dat' using 1:2 title 'lead 1' with lines, '< head -1024 /tmp/a.dat' using 1:3 title 'lead 2' with lines  
=end
def sig_212_to_array(buf)
  buf.bytes.each_slice(3).collect do |data|
    a = ((data[1] & 0x0F) << 8) | data[0]
    b = ((data[1] & 0xF0) << 4) | data[2]
    [a,b]
  end
end

if __FILE__ == $0
  ARGV.each do |path| 
    File.open(path, 'rb') do |f| 
      data = sig_212_to_array(f.read) 
      data.each_with_index { |(a,b),x| puts x.to_s + "\t" + a.to_s + "\t" + b.to_s }
    end
  end
end
