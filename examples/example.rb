#! /usr/bin/env ruby

require 'stash/sword2'

include Stash::Sword2

username, password = ARGV
collection = 'um_lib_web'

client = Client.new(
  username: username,
  password: password,
  collection_uri: URI("http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/#{collection}")
)

doi = "doi:10.5072/FK#{Time.now.to_i}"
zipfile = File.expand_path('../uploads/example.zip', __FILE__)

client.create(doi: doi, zipfile: zipfile)
