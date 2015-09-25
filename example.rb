#!/usr/bin/env ruby

require 'stash/wrapper'

module Stash::Wrapper
  datacite_path = 'spec/data/wrapper/wrapper-2-payload.xml'

  datacite_xml = File.read(datacite_path)
  datacite_resource_element = REXML::Document.new(datacite_xml).root

  wrapper = StashWrapper.new(
    identifier: Identifier.new(type: IdentifierType::DOI, value: '10.14749/1407399498'),
    version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
    license: License::CC_BY,
    embargo: Embargo.new(type: EmbargoType::DOWNLOAD, period: '1 year', start_date: Date.new(2014, 8, 18), end_date: Date.new(2013, 8, 18)),
    inventory: Inventory.new(
      files: [
        StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'),
        StashFile.new(pathname: 'formats.sas7bcat', size_bytes: 78_910, mime_type: 'application/x-sas-catalog'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.sas', size_bytes: 11_121, mime_type: 'application/x-sas'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.sav', size_bytes: 31_415, mime_type: 'application/x-sav'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.sps', size_bytes: 16_171, mime_type: 'application/x-spss'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.dta', size_bytes: 81_920, mime_type: 'application/x-dta'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.dct', size_bytes: 212_223, mime_type: 'application/x-dct'),
        StashFile.new(pathname: 'HSRC_MasterSampleII.do', size_bytes: 242_526, mime_type: 'application/x-do')
      ]),
    descriptive_elements: [datacite_resource_element]
  )

  wrapper_xml = wrapper.save_to_xml

  formatter = REXML::Formatters::Pretty.new
  formatter.compact = true
  puts formatter.write(wrapper_xml, '')
end
