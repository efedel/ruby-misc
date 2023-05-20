#!/bin/env ruby
require 'net/http'
require 'json'
require 'ostruct'
require 'optparse'
require 'nokogiri'
require 'rack/utils'

def parse_imdb_description(html_str)
  doc = Nokogiri::HTML( html_str )
  pres = doc.css('span[role="presentation"]')
  pres ? pres.css('span[data-testid="plot-l"]').text : ''
end

def imdb_description_from_url(url, opts)
  html_str = imdb_send(url, opts)
  html_str ? parse_imdb_description(html_str) : ''
end

def fetch_details(imdb_title, opts)
  url = 'https://www.imdb.com' + imdb_title
  imdb_send(url, opts)
end

def lookup_title(title, opts)
  title_esc = Rack::Utils.escape_html(title)
  url = "https://www.imdb.com/find/?q=#{title_esc}&s=tt&exact=true&ref_=fn_tt_ex"
  imdb_send(url, opts)
end

def imdb_send(url, opts)
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = opts[:user_agent]
  resp = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => (uri.scheme == 'https')) {|http|
    http.request(request)

  }
  if resp.code.to_i != 200
    puts "Did not get HTTP 200 (OK). Details:"
    puts resp.class.name
    puts resp.code
    puts resp['content-type']
    puts resp.body
    puts resp.message
    return
  end

  resp.body
end

def imdb_lookup_title(title, opts={})
  opts[:user_agent] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36"
  title.gsub!(/[^[:alnum:]]/, ' ')

  html_str = lookup_title(title, opts)
  return if ! html_str
  return if html_str.empty?

  doc = Nokogiri::HTML( html_str )
  return if ! doc

  hits = doc.at_css('ul.ipc-metadata-list')
  if ! hits
    $stderr.puts "No metadata list for #{title}"
    return
  end

  # FIXME: iterate over children getting most likely match
  match = hits.children[0]
  if  (! match )
    $stderr.puts "No match for '#{title}'"
    return
  end

  a_tag = match.css('a')
  imdb_title =  a_tag.attribute('href').value 
  match_title = a_tag.children.text  
  match_date = doc.at_css('ul.ipc-inline-list').children[0].text

  if imdb_title and match_title
    $stderr.puts "Looking up '#{match_title}' at http://imdb.com#{imdb_title}"
    desc = imdb_description(imdb_title)
    html_str = fetch_details(imdb_title, opts)
    descr = parse_imdb_description(html_str) 
    [match_title, match_date, "https://www.imdb.com" + imdb_title, descr]
  else 
    []
  end
end

if __FILE__ == $0
  arr = imdb_lookup_title(ARGV.join(' ')) || []
  puts arr.join('|')
end
