require 'rubygems'
require 'sinatra'
require File.expand_path '../app.rb', __FILE__

 log = File.new("./log/lowlevel.log", "a+")
  $stdout.reopen(log)
  $stderr.reopen(log)

run App.new
