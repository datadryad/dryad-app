#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'rack/utils'
require 'byebug'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'pp'
require 'httparty'
require_relative 'uploader'
require 'fileutils'

# create directories if needed
%w[json-reports json-state tmp].each do |dirname|
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
end

#### setup the script ####
state_hash = JSON.parse(File.read('json-state/statefile.json'))
# like { "2010-02" => { "id" => "4b7ce134-d522-44ba-9b58-a00d86791773", "last_processed_day" => 31 }
month_year = ARGV[0].strip
month_state = state_hash[month_year]
puts "original state=#{month_state}"
month_state = { 'id' => nil } if month_state.nil?

puts "uploading report for #{month_year}"

uploader = Uploader.new(report_id: month_state['id'], file_name: "json-reports/#{month_year}.json")
report_id = uploader.process
month_state['id'] = report_id
puts "after state=#{month_state}"

#### save the output again
state_hash[month_year] = month_state
File.open('json-state/statefile.json', 'w') { |f| f.write(JSON.pretty_generate(state_hash)) }
