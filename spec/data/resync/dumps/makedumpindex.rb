#!/usr/bin/env ruby

require 'resync'

formatter = REXML::Formatters::Pretty.new
formatter.compact = true
formatter.width = 80

url_base = 'http://example.org'
cap_list_uri = URI('http://example.org/capability-list.xml')

at_earliest = nil
completed_latest = nil

dump_resources = (1..2).map do |d|
  dump = Resync::XMLParser.parse(File.new("resourcedump#{d}/resourcedump#{d}.xml"))

  at_earliest = dump.at_time unless at_earliest && at_earliest <= dump.at_time
  completed_latest = dump.completed_time unless completed_latest && completed_latest >= dump.completed_time

  ::Resync::Resource.new(
    uri: URI("#{url_base}/resourcedump#{d}/resourcedump#{d}.xml"),
    metadata: ::Resync::Metadata.new(at_time: dump.at_time)
  )
end

index = ::Resync::ResourceDumpIndex.new(
  resources: dump_resources,
  links: [Resync::Link.new(rel: 'up', uri: cap_list_uri)],
  metadata: ::Resync::Metadata.new(
    capability: 'resourcedump',
    at_time: at_earliest,
    completed_time: completed_latest
  )
)

index_xml = index.save_to_xml

index_file = 'resourcedumpindex.xml'
File.open(index_file, 'w') do |f|
  f.puts('<?xml version="1.0" encoding="UTF-8"?>')
  formatter.write(index_xml, f)
  f.puts
end

