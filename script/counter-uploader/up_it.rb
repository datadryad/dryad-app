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
require 'fileutils'
require 'yaml'

state_hash = JSON.parse(File.read('json-state/statefile.json'))
hub_api_token = YAML.load_file('json-state/secrets.yaml')['hub_api_token']
hub_base_url = YAML.load_file('json-state/config.yaml')['hub_base_url']


filenames = Dir.glob('json-reports/*.json').sort

filenames.each do |fn|
  puts "Starting #{fn}"
  month_key = fn.match(/\d{4}-\d{2}/).to_s
  month_info = state_hash[month_key]

  response = HTTParty.put("#{hub_base_url}/reports/#{month_info['id']}",
    body: File.open(fn, 'r').read,
    headers: {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{hub_api_token}" },
    timeout: 300)

  # response.headers are useful
  # response.code should be 200
  puts response.headers
  puts response.code
  puts "Finished #{fn}\r\n\r\n"
  sleep 120
end

