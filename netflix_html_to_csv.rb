#!/usr/bin/env ruby
# convert netflix DVD history to CSV file

require 'nokogiri'
require 'date'

DELIM=','

str = File.read(ARGV.shift)
str.force_encoding("utf-8")
doc = Nokogiri::HTML5(str)

puts ['Title', 'Year', 'WatchedDate'].join(DELIM)

doc.xpath('//ul[@class="historylist"]/li').each do |li|
  title = li.xpath('div[@class="title"]/p/a').text.strip
  next if title.empty?

  year = li.xpath('div[@class="title"]/p[@class="metadata"]/span').first.text.strip  

  ts = li.xpath('div[@class="shipped"]').text.strip.sub(/\/([0-9]+)$/, '/20\1')
  # fix idiotic netflix date encoding
  ts_arr = ts.split('/') 
  ts = [ts_arr[2], ts_arr[0], ts_arr[1]].join('/')
  date = Date.parse(ts)

  puts [title.inspect, year, date.strftime("%Y-%m-%d")].join(DELIM)
end

=begin
# EXAMPLE ENTRY:

<li aria-label="Table row for Teorema" id="70039263"><div class="position">3</div> <div class="boxart"><a href="https://dvd.netflix.com/Movie/Teorema/70039263" data-movieid="70039263" class=" boxart bob-modal-only"><img src="netflix-dvd-history_files/70039263.jpg" aria-label="Teorema" class="no-bob mmodal" width="52"></a> <!----></div>
<div class="title"><p><a href="https://dvd.netflix.com/Movie/Teorema/700392
63" data-movieid="70039263" class=" title mmodal bob-modal-only">Teorema</a></p>
 <p class="metadata"><span>1968</span><span class="mpaa">NR</span><span class="d
iscOrDuration">1h 45m</span></p></div> <div class="rating"><span><span class="st
arbar canrate done" data-rating="1.6" data-userrating="0" data-movie="70039263"
data-ratingdelay="0"><span class="star-mask"></span><span class="red-star-mask" style="width: 31px;"></span></span></span></div><div class="shipped">10/13/22</div> <div class="returned"><span>Returned </span>10/25/22</div> 
=end
