#! /usr/bin/env ruby

require 'stash/sword2'

include Stash::Sword2

username, password, collection = ARGV

client = Client.new(
  username: username,
  password: password,
  collection_uri: URI("http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/#{collection}")
)

doi = "doi:10.5072/FK#{Time.now.to_i}"
zipfile = File.expand_path('../uploads/example.zip', __FILE__)

receipt = client.create(doi: doi, zipfile: zipfile)
em_iri = receipt.em_iri
se_iri = receipt.se_iri

puts "em_iri: #{em_iri}"
puts "se_iri: #{se_iri}"

code = client.update(se_iri: se_iri, zipfile: zipfile)
puts "update response code: #{code}"
