#!/usr/bin/env ruby
# Search meaningless drivel ala https://dev.twitter.com/docs/api/1/get/search
#   Usage: twitsearch ARG [...]
#   ... where KEY is 'search term', http://URL, @username, or #hashtag.
#   Any number of arguments can be provided.
# NOT FOR REDISTRIBUTION -- use 'twitter' gem.

require 'ostruct'
require 'optparse'

require 'net/http'
require 'uri'

require 'rubygems'
require 'json/ext'
require 'oauth'

# ----------------------------------------------------------------------
# OAUTH
=begin
This reads twitter app credentials (obtained from https://dev.twitter.com/apps)
from a file with the following format:

#!/usr/bin/env ruby
CONSUMER_KEY = '######################'
CONSUMER_SECRET = '########################################'
ACCESS_TOKEN = '##################################################'
ACCESS_SECRET = '#############################################'
=end
$twitter_oauth_path ||= File.join(ENV['HOME'], '.twitter.oauth.rb')
if File.exist? $twitter_oauth_path
  load $twitter_oauth_path
end


# ----------------------------------------------------------------------
=begin rdoc
A twitter API search encapsulated in an object.
Options:
  query_terms [any number of strings. URLS, #hashtags and @usernames allowed]
  twit_type : popular, recent, mixed
  max # (max per-page)
  page # (page number to retrieve)
  geocode : latitude, longitude, radius
  until : YYYY-MM-DD
Examples (from https://dev.twitter.com/docs/using-search)
watching now 	containing both "watching" and "now".
"happy hour" 	containing the exact phrase "happy hour".
love OR hate 	containing either "love" or "hate" (or both).
beer -root 	containing "beer" but not "root".
#haiku 	containing the hashtag "haiku".
from:alexiskold 	sent from person "alexiskold".
to:techcrunch 	sent to person "techcrunch".
@mashable 	referencing person "mashable".
superhero since:2010-12-27 	containing "superhero" and sent since date "2010-12-27" (year-month-day).
ftw until:2010-12-27 	containing "ftw" and sent before the date "2010-12-27".
movie -scary :) 	containing "movie", but not "scary", and with a positive attitude.
flight :( 	containing "flight" and with a negative attitude.
traffic ? 	containing "traffic" and asking a question.
hilarious filter:links 	containing "hilarious" and linking to URL.
news source:twitterfeed 	containing "news" and entered via TwitterFeed
=end

class TwitSearch
  PREFIX = 'TW'
  URL  = 'https://api.twitter.com/1.1/search/tweets.json'

=begin rdoc
TwitterSearch result.
=end
  class Result
    attr_reader :created, :from_id, :from_name, :to_id, :to_name
    attr_reader :id, :geo, :urls, :hashtags, :body

    def initialize(h)
      @created = h['created_at']
      @from_id = h['user']['screen_name']
      @from_name = h['user']['name']
      @to_id = h['in_reply_to_screen_name']
      @body = h['text']
      @id = h['id_str']
      @geo = h['geo']
      @urls = ((h['entities'] || {})['urls'] || []).map { |e|
        e['expanded_url']
      }
      @hashtags = ((h['entities'] || {})['hashtags'] || []).map { |e|
        e['text']
      }
    end

=begin rdoc
Return a human-readable version of results.
=end
    def report
      header_str =  "%s : %s(%s) -> %s" % [ created, from_id, from_name, 
                                            (to_id || '[*]') ]
      [header_str, body, urls.join(' ')].join("\n")
    end

=begin rdoc
Return a pipe-delimited version of results.
=end
    def raw
      [id, created, from_id, from_name, to_id, geo, urls.join(' '),
       body].join('|')
    end

  end

  def self.prefix; PREFIX; end

  def initialize(options)
    @oauth = prepare_access_token
    query_str = URI.encode( options.query_terms.inject([]){ |a, arg| a << arg; a }.join('+') )
    # NOTE: URI.encode does NOT encode '@', which Twitter expects to be encoded.
    query_str.gsub!(/@/, '%40')
    query_str.gsub!(/:/, '%3A')
    query_str.gsub!(/\(/, '%28')
    query_str.gsub!(/\)/, '%29')
    query_str.gsub!(/\?/, '%3F')
    args = "result_type=%s&count=%d&include_entities=true" % [
      options.twit_type, options.max]
    args += "&until=#{options.until}" if options.until
    args += "&gecode=#{options.gecode}" if options.geocode
    @url = "#{URL}?#{args}&q=#{query_str}"
  end

  def prepare_access_token
    consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET,
      { :site => "http://api.twitter.com",
        :scheme => :header
      })
    OAuth::AccessToken.from_hash(consumer, { :oauth_token => ACCESS_TOKEN, 
                                 :oauth_token_secret => ACCESS_SECRET } )
  end

=begin rdoc
Iterate over each TwitterSearch::Results object.
=end
  def each(&block)
    raise "TWITTER REQUIRES OAUTH!" if ! @oauth

    result = @oauth.get(@url)
    if (result.is_a? Net::HTTPUnauthorized)
      $stderr.puts "Not authorized!: #{result.body}"
      return
    end

    (JSON.parse(result.body)['statuses'] || []).map { |hit| 
      Result.new(hit)
    }.each(&block)
  end

=begin rdoc
Return header of pipe-delimited data
=end
    def self.raw_header
      %W{ id created from_id from_name to_id geo urls body }.join('|')
    end
end

# ----------------------------------------------------------------------
=begin rdoc
A facebook Graph API search encapsulated in an object.
Options:
  query_terms
=end
class FbSearch
  PREFIX = 'FB'
  URL  = 'http://graph.facebook.com/search'
  TYPE = 'post'  # post user page event group place
  ARGS = "type=#{TYPE}"

  class Result
    attr_reader :id, :from_id, :from_name, :created, :type, :application, :name
    attr_reader :caption, :description, :message, :link, :source, :story
    attr_reader :body, :urls
    def initialize(h)
      @id = h['id']
      @from_name = (h['from']||{})['name']
      @from_id = (h['from']||{})['name']
      @created = h['created_time']
      @type = h['type']
      @application = h['application']
      @name = h['name']
      @caption = h['caption']
      @description = h['description']
      @message = h['message']
      @link = h['link']
      @source = h['source']
      @story = h['story']

      @urls = []
      @urls << @link if @link

      @body = @message || @description || @caption || @story
      # TODO: properties message_tags picture updated_time icon object_id 
    end

=begin rdoc
Return a human-readable version of results.
=end
    def report
      header_str =  "%s : %s (%s) '%s'" % [ created, from_name, from_id, name]
      header_str += " (via #{source})" if source
      [header_str, body, urls.join(' ')].join("\n")
    end

=begin rdoc
Return a pipe-delimited version of results.
=end
    def raw
      [id, created, type, application, from_name, from_id, name, caption,
       description, message, story, link, source].join('|')
    end

  end

  def self.prefix; PREFIX; end

  def initialize(options)
    # TODO: something a little better. does this thing have any options?
    query_str = URI.encode( options.query_terms.inject([]){ |a, arg| 
      a << clean(arg); a 
    }.join('+') )
    @url = "#{URL}?#{ARGS}&q=#{query_str}"
  end

=begin rdoc
Remove TwitSearch '#' and '@' from start of query term.
=end
  def clean(arg)
    (arg.start_with? '@') || (arg.start_with? '#') ? arg[1..-1] : arg
  end

=begin rdoc
Iterate over each FbSearch::Result object
=end
  def each(&block)
    (JSON.parse(Net::HTTP.get URI.parse(@url))['data'] || []).map { |hit| 
      Result.new(hit)
    }.each(&block)
  end

=begin rdoc
Return header of pipe-delimited data
=end
    def self.raw_header
      %W{id created type application from_name from_id name caption
         description message story link source}.join('|')
    end
end


# ----------------------------------------------------------------------
# Application code
module TwitSearchApp

  def self.handle_options(args)
    options = OpenStruct.new
    options.query_terms = []
    options.twit = true
    options.twit_type = 'mixed'
    options.fb = true
    options.fb_type = 'post'
    options.max = 100
    options.page = 1
    options.geocode = nil
    options.until = nil
    options.debug = false
    options.header = false
    options.raw = false
    options.strict = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename $0} TERM [...]"
      opts.separator "TERM can be a URL, #hashtag, @name, or keyword"
      opts.separator ""
      opts.separator "Twitter Options:"
      opts.on('-T', '--no-twit', 'Disable twitter') {options.twit = false}
      opts.on('-t', '--twit-type str', 
              'Twit search type: recent, popular, mixed [default]') { |str|
        options.twit_type = str
      }
      opts.on('-g', '--geocode str', 'Twit Geocode : latitude,longitude,radius'
             ) { |str|
        options.geocode = str
      }
      opts.on('-m', '--max num', 'Max number of hits [100]') { |num|
        options.max = Integer(num)
      }
      opts.on('-p', '--page num', 'Page number to return [1]') { |num|
        options.page = Integer(num)
      }
      opts.on('-b', '--before str', 'Limit to posts before date: YYYY-MM-DD'
             ) { |str|
        options.until = str
      }

      opts.separator "Facebook Options:"
      opts.on('-F', '--no-fb', 'Disable facebook') {options.fb = false}
      opts.on('-f', '--fb-type str', 
              'FB search type: post [default] user page event group place') {|str|
        options.fb_type = str
      }

      opts.separator "Generic Options:"
      opts.on('-D', '--debug', 'Print debug output') { options.debug = true }
      opts.on('-H', '--header', 'Include header for raw output') { 
        options.header = true 
      }
      opts.on('-r', '--raw', 'Print pipe-delimited output') { options.raw = true }
      opts.on('-s', '--strict', 'Limit to results containing phrase') { options.strict = true }
      opts.on_tail('-h', '--help', 'Show help screen') { puts opts; exit 1 }
    end

    opts.parse! args
    while args.length > 0
      options.query_terms << args.shift
    end

    if options.query_terms.empty?
      $stderr.puts 'SEARCH TERM REQUIRED'
      puts opts
      exit -1
    end

    options
  end

# print individual search result in either raw or human-readable format
  def self.print_result(result, cls, options, prev)
    if options.raw
      puts "#{cls.prefix}|" + result.raw
    else
      puts '====================================' if prev
      puts "[%s] %s" % [cls.prefix, result.report]
    end
  end

# Invoke the search class and print results
  def self.do_search(cls, options, prev=false)
    puts "#{cls.prefix}|" + cls.raw_header if options.raw && options.header
    cls.new(options).each do |hit|
      $stderr.puts hit.inspect if options.debug
      if options.strict
        str = hit.raw
        all = true
        options.query_terms.each { |q| all = false if str !~ /#{q}/i }
        next if not all
      end
      print_result(hit, cls, options, prev)
      prev = true
    end
    prev
  end
end

# ----------------------------------------------------------------------
# main()
if __FILE__ == $0
  options = TwitSearchApp.handle_options(ARGV)

  prev = TwitSearchApp.do_search(TwitSearch, options) if options.twit
  prev = TwitSearchApp.do_search(FbSearch, options, prev) if options.fb
end
