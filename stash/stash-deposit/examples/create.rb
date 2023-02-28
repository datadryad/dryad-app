#! /usr/bin/env ruby

require 'stash/sword'

include Stash::Sword

password = ARGV[0]
username = 'ucop_dash_submitter'
collection = 'dash_cdl'
collection_uri = "http://sword-aws-dev.cdlib.org:39001/mrtsword/collection/#{collection}"
zipfile = File.expand_path('uploads/example.zip', __dir__)

doi = "doi:10.5072/FK#{Time.now.to_i}"

client = Client.new(
  username: username,
  password: password,
  collection_uri: URI(collection_uri)
)

receipt = client.create(doi: doi, zipfile: zipfile)
em_iri = receipt.em_iri
edit_iri = receipt.edit_iri

puts "em_iri: #{em_iri}"
puts "edit_iri: #{edit_iri}"
