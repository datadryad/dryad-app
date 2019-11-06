#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'rack/utils'
require 'byebug'
require 'json'
require 'pp'
require 'httparty'
require 'cgi'

# json file gotten by
# curl "https://api.datacite.org/reports?client-id=cdl.dash&page\[size\]=200" > reports_submitted.json
reports_hash = JSON.parse(File.read('reports_submitted.json'))
reps = reports_hash['reports']

reps.map! do |rep|
  "#{rep['report-header']['reporting-period']['begin-date']}\t#{rep['id']}"
end.sort!

# reps.each do |rep|
#   puts rep
# end

reps.each do |rep|
  subj_id = "https://api.datacite.org/reports/#{rep.split("\t")[1]}"
  str = "https://api.datacite.org/events?source-id=datacite-usage&subj-id=#{CGI.escape(subj_id)}"
  # puts str
  resp = HTTParty.get(str)

  if resp['meta']['total'] == 0 || resp['meta']['total-pages'] == 0
    puts "#{rep} -- no data"
  else
    puts "#{rep} -- total pages: #{resp['meta']['total-pages']}"
  end
  puts "     #{str}"
  puts ''
  # resp = HTTParty.get("https://api.datacite.org/reports/#{rep.split("\t")[1]}")
  # puts "Getting #{rep} #{resp.headers['status']}"
end

puts 'fin'
