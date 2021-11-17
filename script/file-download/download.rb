#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'http'
require 'json'
require 'byebug'
require 'cgi'
require 'fileutils'
require 'yaml'
require_relative('./copy_file')

# set up config file
config_file = if File.exist?(File.join('C:', 'DryadData', 'api_config.yml'))
                File.join('C:', 'DryadData', 'api_config.yml')
              elsif File.exist?(File.join(Dir.home, '.api_config.yml'))
                File.expand_path(File.join(Dir.home, '.api_config.yml'))
              else
                nil
              end

if config_file.nil?
  puts "The config file doesn't exist. It should be at C:\\DryadData\\api_config.yml in Windows or ~/.api_config.yml in Linux."
  puts "It should contain these:"
  puts ''
  puts "base_url: https://datadryad.org"
  puts "api_key: <your-api-key>"
  puts "api_secret: <your-api-secret>"
  puts "base_path: <save-path>"
  puts ''
  puts "# The base_path above is just the top level directory. Users may choose another directory under it if they wish."
  exit(false)
end

# read mini-config for api access
config_info = YAML.load_file(config_file)
base_url = config_info['base_url'] # /api/v2
api_key = config_info['api_key']
api_secret = config_info['api_secret']
base_path = File.expand_path(config_info['base_path'])

# Ask for the DOI they want to retrieve
puts "This is an initial testing version of a script to download files directly from the API. That avoids a lot of time and wasted"
puts "resources creating zip packages and unzipping them."
puts ''
puts "If you encounter problems, please let us know at https://github.com/CDL-Dryad/dryad-product-roadmap/projects/1 in the Backlog."
puts ''

puts "Copy/paste the Dryad landing URL or type it below (format like doi:xxxxx/xxxxx) and press enter:"
proposed_doi = gets.strip
proposed_doi = CGI.unescape(proposed_doi) # in case the landing page URL has escaped slashes in it, since I think geoblacklight does that sometimes

starting_index = proposed_doi.index('doi:')
if starting_index.nil?
  STDERR.puts "Cannot find the doi:xxxxx/xxxxxxx formatted string in what you entered"
  exit(false)
end

# add to base_path with username because of shared data directory in curator PC
base_path = File.join(base_path, (ENV['USER'] || ENV['USERNAME']) )

doi = proposed_doi[starting_index..-1].strip
esc_doi = CGI.escape(doi)

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
response = http.get("#{base_url}#{json['_links']['stash:versions']['href']}?per_page=100", headers: default_headers)
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

# make the directory (doi), including version to save to.  Version good so curators don't overwrite different versions
# and then get confused when files may be different.
save_path = File.join(base_path, doi.gsub(/[~"#%&*:<>?\/\{|}]/, '_'), "v#{last_version['versionNumber']}")
FileUtils.mkdir_p(save_path)
copy_file = CopyFile.new(save_path: save_path)

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

puts "Done retrieving latest submitted files for #{doi} at #{save_path}"