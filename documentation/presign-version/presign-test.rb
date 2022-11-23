#!/usr/bin/env ruby
# info about endpoints at https://github.com/CDLUC3/mrt-doc/blob/main/endopoints/pre-signed-urls.md#phase-2
require 'byebug'
require 'http'
require 'active_support/all'
require 'erb'
require 'pp'
require 'rack/utils'
include ERB::Util
# allows url_encode(thing)

mrt_domain = 'merritt-stage.cdlib.org'
username = '<fill-me>'
password = '<fill-me>'

# resource_id = 2919
ark = 'ark:/99999/fk41v6v38t'
version = 1

# this one is a little bigger
# or resource_id = 2920
# ark = 'ark:/99999/fk4x364g27'
# version = 1

http = HTTP.timeout(connect: 30, read: 30).timeout(1.hour.to_i).follow(max_hops: 10)
           .basic_auth(user: username, pass: password)

# --- Assemble Request ---

assemble_version_url = URI::HTTPS.build(
    host: mrt_domain,
    path: File.join('/api', 'assemble-version', url_encode(url_encode(ark)), version.to_s),
    query: {format: 'zipunc', content: 'producer'}.to_query)

puts "The ASSEMBLE call"
puts "--- GET: #{assemble_version_url} ---"
resp = http.get(assemble_version_url)
puts "Successfully called assemble presigned url = #{resp.status.success?}\n"
puts "HEADERS"
puts "-------"
pp(resp.headers.to_h)
puts "\nJSON body"
puts "---------"
json1 = resp.parse.with_indifferent_access
pp(json1)


# --- Status Call ---
json2 = {}

puts "\n\nThe STATUS call"
status_call = URI::HTTPS.build(
    host: mrt_domain,
    path: File.join('/api', 'presign-obj-by-token', url_encode(json1[:token])),
    query: {no_redirect: true, filename: 'funn_with_downloads.zip'}.to_query)

# poll until ready
while json2.empty? || json2[:status] == 202 do
  puts "\n\n\n--- GET: #{status_call} ---"
  resp = http.get(status_call)
  puts "Successfully called status for presigned url = #{resp.status.success?}\n"
  puts "HEADERS"
  puts "-------"
  pp(resp.headers.to_h)
  puts "\nJSON body"
  puts "---------"
  json2 = resp.parse.with_indifferent_access
  pp(json2)
  sleep 2
end

# Check presigned URL and head request
s3_url = json2[:url]

puts "\n\n\nS3 URL readable query params"
query_params = Rack::Utils.parse_nested_query(URI.parse(s3_url).query)
pp(query_params)

puts "\n\nAn S3 head request"
resp = http.head(s3_url)
pp(resp.headers.to_h)





