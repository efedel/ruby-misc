#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require "sinatra/json"

set :port, 80

get '/*' do
  :json #{ }
  #json({:foo => 'bar'}, :encoder => :to_json, :content_type => :js)
end
