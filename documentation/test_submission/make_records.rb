#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'byebug'
require 'faker'
require 'securerandom'
require 'fileutils'

app_id = ''
secret = ''
email = ''

domain_name = 'http://localhost:3000'
response = RestClient.post "#{domain_name}/oauth/token", {
    grant_type: 'client_credentials',
    client_id: app_id,
    client_secret: secret
}
token = JSON.parse(response)['access_token']



headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{token}" }
resp = RestClient.get "#{domain_name}/api/test", headers
j = JSON.parse(resp)
raise 'Invalid API connection' if j['user_id'].nil?
puts "Logged in as #{j['user_id']}"


PATCH_SUBMISSION = [{ "op": "replace", "path": "/versionStatus", "value": "submitted" }].to_json.freeze

(1).upto(100) do |i|

  puts "##{i}"
  metadata_hash = {'title': Faker::Lorem.words(rand(10)+1).map(&:capitalize).join(" "),
    'authors': [{'firstName': Faker::Name.first_name, 'lastName': Faker::Name.last_name, 'email': email, 'affiliation': Faker::University.name}],
    'abstract': Faker::Lorem.paragraph }

  puts "  creating ds w/ title: #{metadata_hash[:title]}"
  # create new dataset with metadata
  resp = RestClient.post "#{domain_name}/api/datasets", metadata_hash.to_json, headers
  return_hash = JSON.parse(resp)
  doi = return_hash['identifier']
  doi_encoded = CGI.escape(doi)

  puts "  creating file"
  # create a file of random data
  fn = "#{Faker::Name.first_name}.txt"
  one_megabyte = 1_000_000
  size = rand(50) + 1
  File.open(fn, 'wb') do |f|
    size.to_i.times { f.write( SecureRandom.random_bytes( one_megabyte ) ) }
  end

  puts "  uploading the file: #{fn}"
  content_type = 'text/plain'
  resp = RestClient.put(
      "#{domain_name}/api/datasets/#{doi_encoded}/files/#{URI.escape(fn)}",
      File.read(fn),
      headers.merge({'Content-Type' => content_type})
  )
  return_hash = JSON.parse(resp)
  raise 'Bad upload' if resp.code != 201

  puts "  submitting the dataset"
  # submit the dataset to the storage repository
  resp = RestClient.patch(
      "#{domain_name}/api/datasets/#{doi_encoded}",
      PATCH_SUBMISSION,
      headers.merge({'Content-Type' =>  'application/json-patch+json'})
  )
  raise 'Bad submission to the storage repository' if resp.code != 202

  FileUtils.rm(fn)

end
