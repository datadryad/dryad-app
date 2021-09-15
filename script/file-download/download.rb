#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'http'
require 'json'
require 'byebug'
require 'cgi'
require 'fileutils'
require_relative('./copy_file')

if ARGV.length != 1
  puts 'Call this script with one DOI or landing URL (with doi at the end) to download the files to a local directory'
  puts 'Example: ./download.rb http://localhost:3000/stash/dataset/doi:10.5072/FK2X92972F'
  exit
end

proposed_doi = ARGV.first
starting_index = proposed_doi.index('doi:')
if starting_index.nil?
  STDERR.puts "Cannot find the doi:xxxxx/xxxxxxx type string in what you entered"
  exit(false)
end

doi = proposed_doi[starting_index..-1].strip
esc_doi = CGI.escape(doi)

base_url = 'https://dryad-dev.cdlib.org' # /api/v2
api_key = 'fill-me-in'
api_secret = 'fill-me-in'
base_path = File.expand_path(__dir__)

save_path = File.join(base_path, doi.gsub(/[~"#%&*:<>?\/\{|}]/, '_'))
FileUtils.mkdir_p(save_path)

# The change here from the default normalizer in http.rb is that this was the old value :path => uri.normalized_path
NORMALIZER = ->(uri) do
  uri = HTTP::URI.parse uri

  HTTP::URI.new(
    scheme: uri.normalized_scheme,
    authority: uri.normalized_authority,
    path: uri.path,
    query: uri.query,
    fragment: uri.normalized_fragment
  )
end

# --------------------------------------
# set up http client with basic settings
# --------------------------------------
http = HTTP.use(normalize_uri: { normalizer: NORMALIZER }).timeout(connect: 30, read: 30, write: 30).follow(max_hops: 10)
copy_file = CopyFile.new(save_path: save_path)

# get access token for authenticated access and set up default headers
response = http.post("#{base_url}/oauth/token", json: {grant_type: 'client_credentials', client_id: api_key, client_secret: api_secret})
if response.code > 399
  STDERR.puts "API access was not unauthorized"
  exit(false)
end
access_token = response.parse['access_token']
default_headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{access_token}" }

# ----------------------
# test that access works
# ----------------------
response = http.get("#{base_url}/api/v2/test", headers: default_headers)
if response.parse['message'].start_with?('Welcome application owner')
  puts 'Authenticated with API'
else
  STDERR.puts 'Problem authenticating with API'
  exit(false) # bad termination status
end

# -----------------------
# Get dataset information
# -----------------------
puts "Finding #{doi} in the API"
response = http.get("#{base_url}/api/v2/datasets/#{esc_doi}", headers: default_headers)
if response.code > 399
  STDERR.puts "Couldn't find the DOI"
  exit(false) # bad termination status
end
json = response.parse

# ------------
# Get versions
# ------------
response = http.get("#{base_url}#{json['_links']['stash:versions']['href']}", headers: default_headers)
json = response.parse

# -------------------------
# Get last page of versions
# -------------------------
response = http.get("#{base_url}#{json['_links']['last']['href']}", headers: default_headers)
json = response.parse

# --------------------------
# Get last submitted version
# --------------------------
last_version = nil
json['_embedded']['stash:versions'].reverse.each do |v|
  if v['versionStatus'] == 'submitted'
    last_version = v
    break
  end
end

# ----------------------------------
# Get the list of files and download
# ----------------------------------
response = http.get("#{base_url}#{last_version['_links']['stash:files']['href']}", headers: default_headers)

page = "#{base_url}#{last_version['_links']['stash:files']['href']}"
while (response = http.get(page, headers: default_headers)) do
  json = response.parse
  # another loop to download each file
  json['_embedded']['stash:files'].each do |file_info|
    if file_info['status'] != 'deleted'
      copy_file.save(url: "#{base_url}#{file_info['_links']['stash:file-download']['href']}",
                     token: access_token,
                     filename: file_info['path'])
      puts ''
      sleep 1 # to prevent us hitting the API limits by too many requests
    end
  end
  break if json['_links']['next'].nil?
  page = "#{base_url}#{json['_links']['next']['href']}"
end

puts "Done retrieving latest submitted files for #{doi}"