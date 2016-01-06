#! /usr/bin/env ruby

require 'stash/wrapper'
require 'datacite/mapping'

include Stash::Wrapper

datacite_file = 'spec/data/wrapped_datacite/datacite-example-full-v3.1.xml'
datacite_example = REXML::Document.new(File.read(datacite_file)).root

wrapper_example = StashWrapper.new(
  identifier: Identifier.new(type: IdentifierType::DOI, value: '10.5072/example-full'),
  version: Version.new(number: 4, date: Date.new(2014, 10, 17), note: 'Full DataCite 3.1 XML Example accessed 2014-01-06'),
  license: License.new(
    name: 'CC0 1.0 Universal',
    uri: URI('http://creativecommons.org/publicdomain/zero/1.0/')
  ),
  embargo: Embargo.new(type: EmbargoType::DOWNLOAD, period: '1 year', start_date: Date.new(2014, 10, 17), end_date: Date.new(2015, 10, 17)),
  inventory: Inventory.new(files: [StashFile.new(pathname: 'datacite-example-full-v3.1.xml', size_bytes: 3072, mime_type: 'application/xml')]),
  descriptive_elements: [datacite_example]
)

puts wrapper_example.write_xml
