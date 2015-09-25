#!/usr/bin/env ruby

require 'stash/wrapper'

ST = Stash::Wrapper

identifier = ST::Identifier.new(
  type: ST::IdentifierType::DOI,
  value: '10.14749/1407399498'
)

version = ST::Version.new(
  number: 1,
  date: Date.new(2013, 8, 18),
  note: 'Sample wrapped Datacite document'
)

license = ST::License::CC_BY

embargo = ST::Embargo.new(
  type: ST::EmbargoType::DOWNLOAD,
  period: '1 year',
  start_date: Date.new(2014, 8, 18),
  end_date: Date.new(2013, 8, 18)
)

inventory = ST::Inventory.new(
  files: [
    ST::StashFile.new(
      pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'
    ),
    ST::StashFile.new(
      pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'
    ),
    ST::StashFile.new(
      pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'
    )
  ])

datacite_file = 'spec/data/wrapper/wrapper-2-payload.xml'
datacite_root = REXML::Document.new(File.read(datacite_file)).root

wrapper = ST::StashWrapper.new(
  identifier: identifier,
  version: version,
  license: license,
  embargo: embargo,
  inventory: inventory,
  descriptive_elements: [datacite_root]
)

wrapper_xml = wrapper.save_to_xml

formatter = REXML::Formatters::Pretty.new
formatter.compact = true
puts formatter.write(wrapper_xml, '')
