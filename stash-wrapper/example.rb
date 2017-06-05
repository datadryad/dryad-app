#!/usr/bin/env ruby

require 'stash/wrapper'

include Stash::Wrapper

identifier = Identifier.new(
  type: IdentifierType::DOI,
  value: '10.14749/1407399498'
)

version = Version.new(
  number: 1,
  date: Date.new(2013, 8, 18),
  note: 'Sample wrapped Datacite document'
)

license = License::CC_BY

embargo = Embargo.new(
  type: EmbargoType::DOWNLOAD,
  period: '1 year',
  start_date: Date.new(2013, 8, 18),
  end_date: Date.new(2014, 8, 18)
)

inventory = Inventory.new(
  files: [
    StashFile.new(
      pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'
    ),
    StashFile.new(
      pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'
    ),
    StashFile.new(
      pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'
    )
  ]
)

datacite_file = 'spec/data/wrapper/wrapper-2-payload.xml'
datacite_root = REXML::Document.new(File.read(datacite_file)).root

wrapper = StashWrapper.new(
  identifier: identifier,
  version: version,
  license: license,
  embargo: embargo,
  inventory: inventory,
  descriptive_elements: [datacite_root]
)

puts wrapper.write_xml
