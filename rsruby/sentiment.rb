#!/usr/bin/env ruby

require 'ostruct'
require 'optparse'

require 'rubygems'
require 'json/ext'
require 'rsruby'
#sudo rvm all do gem install rsruby -- --with-R-home=/usr/lib/R --with-R-include=/usr/share/R/include

# convert R data frames to Ruby dataframes
#require 'dataframe'
#theR.class_table['data.frame'] = lambda{|x| DataFrame.new(x)}
#RSRuby.set_default_mode(RSRuby::CLASS_CONVERSION)

module SentimentR

  def self.initialize_r
    ENV['R_HOME'] ||= detect_r
    @r = RSRuby.instance
    fix_graphics
    @r.eval_R("suppressMessages(library('tm.plugin.webmining'))")
    @r.eval_R("suppressMessages(library('tm.plugin.sentiment'))")
  end

  def self.detect_r
    # TODO: platform-detect
    '/usr/lib/R'
  end

  def self.fix_graphics
    ##R_GRAPHICS_FIX = 'X11.options(type="Xlib")'
    ##R_GRAPHICS_FIX = 'graphics.off(); X11.options(type="nbcairo")'
    #R_GRAPHICS_FIX = 'graphics.off(); X11.options(type="Xlib")'
    ##theR.eval_R(R_GRAPHICS_FIX) if R_GRAPHICS_FIX
  end

  def self.sentiment_analysis(opts)
    terms = {}
    opts.query_terms.each do |term|
      scores = {}
      terms[term] = {}
      opts.engines.each do |engine|
        sentiment_query(build_query(engine, term), opts).each do |k,v| 
          next if k.to_s == 'MetaID'
          terms[term][k] ||= []
          terms[term][k] += v
        end
      end
    end
  end

  def self.sentiment_query(query_str, opts)
    begin
      @r.eval_R("corpus <- WebCorpus(#{query_str})")
      @r.eval_R('corpus <- score(corpus)')
      @r.eval_R('scores <- meta(corpus)')
      calculate_summary(opts.summary_func) if opts.summary_func
    rescue RException => e
      $stderr.puts "ERROR IN QUERY #{query_str.inspect}"
      $stderr.puts e.message
      $stderr.puts e.backtrace[0,3]
      {}
    end
  end

  def self.calculate_summary(fn)
    @r.eval_R("v <- sapply(colnames(scores), function(x) #{fn}(scores[,x]) )")
    #@r.eval_R('as.data.frame(v)')
    v = @r.eval_R('as.list(v)')
    puts v.inspect
    v
  end

  ENGINES = {
    :google_blog => 'GoogleBlogSearchSource',
    :google_finance => 'GoogleFinanceSource',
    :google_news => 'GoogleNewsSource',
    #:nytimes => 'NYTimesSource', # appid = user_app_id
    #:reutersnews => 'ReutersNewsSource', # query: businessNews
    #:twitter => 'TwitterSource',
    :yahoo_finance => 'YahooFinanceSource',
    :yahoo_inplay => 'YahooInplaySource',
    :yahoo_news => 'YahooNewsSource'
  }

  def self.build_query(engine, term)
    # TODO: support nytimes and reuters
    "#{ENGINES[engine]}('#{term}')"
  end

  def self.output_sentiment(term_scores, opts)
    puts term_scores.inspect
  end

  def self.handle_options(args)

    options = OpenStruct.new
    options.engines = []
    options.query_terms = []
    options.summary_func = nil

    # TODO:  raw, json
    #        aggregate
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename $0} TERM [...]"
      opts.separator "descr"
      opts.separator ""
      opts.on('-b', '--google-blog', 'Include Google Blog search') { options.engines << :google_blog }
      opts.on('-f', '--google-finance', 'Include Google Finance search') { options.engines << :google_finance }
      opts.on('-n', '--google-news', 'Include Google News search') { options.engines << :google_news }
      #opts.on('-t', '--twitter', 'Include Twitter search') { options.engines << :twitter }
      opts.on('-F', '--yahoo-finance', 'Include Yahoo Finance search') { options.engines << :yahoo_finance }
      opts.on('-I', '--yahoo-news', 'Include Yahoo News search') { options.engines << :yahoo_news }
      opts.on('-N', '--yahoo-inplay', 'Include Yahoo InPlay search') { options.engines << :yahoo_inplay }
      opts.on('-m', '--median', 'Calculate median') { options.summary_func = 'median' }
      opts.on('-M', '--mean', 'Calculate mean') { options.summary_func = 'mean' }
      #opts.on('-r', '--raw', 'Print pipe-delimited output') { options.raw = true }
      opts.on_tail('-h', '--help', 'Show help screen') { puts opts; exit 1 }
    end

    opts.parse! args
    options.engines << :google_news if options.engines.empty?

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
end

# ----------------------------------------------------------------------
if __FILE__ == $0
  options = SentimentR.handle_options(ARGV)
  SentimentR.initialize_r
  output_sentiment SentimentR.sentiment_analysis(options), options
end

__END__
Polarity: Is the sentiment associated with the entity positive or negative?
Subjectivity: How much sentiment (of any polarity) does the entity garner?
Subjectivity indicates proportion of sentiment to frequency of occurrence, while polarity indicates percentage of positive sentiment references among total sentiment references.
Polarity: num of positive sentiment references / total num of sentiment references
          p - n / p + n
Sentiment: total num of sentiment references / total num of references
           p + n / N
pos_refs_per_ref : total num of positive sentiment references / total num of references
                   p / N
neg_refs_per_ref : total num of negative sentiment references / total num of references
                   n / N
senti_diffs_per_ref : num positive references / total num of references
                      p - n / N

sentence detect
library(openNLP)
Sentence Detection
sentences <- sentDetect(text, language = "en")
filteredSentences <- sentences[grepl(keyword,sentences)]

Headline:
sapply(corpus, FUN=function(x){ attr ( x,"Heading ")})

Description:
desc <- sapply(corpus,FUN=function(x) { attr ( x,"Description ") })
filteredDesc <- desc[grepl(keyword,desc)]

Sentiment words:
tm.plugin.tags

