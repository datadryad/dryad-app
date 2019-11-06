#! /usr/bin/env ruby

require 'stash/sword'

include Stash::Sword

password = ARGV[0]
username = 'ucop_dash_submitter'
collection = 'dash_cdl'
collection_uri = "http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/#{collection}"
zipfile = File.expand_path('uploads/example.zip', __dir__)

edit_iri = 'http://sword-aws-dev.cdlib.org:39001/mrtsword/edit/dash_cdl/doi%3A10.5072%2FFK1465424720'

client = Client.new(
  username: username,
  password: password,
  collection_uri: URI(collection_uri)
)

code = client.update(edit_iri: edit_iri, zipfile: zipfile)
puts "update response code: #{code}"
