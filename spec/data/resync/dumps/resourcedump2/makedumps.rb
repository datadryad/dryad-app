#!/usr/bin/env ruby

require 'resync'

formatter = REXML::Formatters::Pretty.new
formatter.compact = true
formatter.width = 80

url_base = 'http://example.org/resourcedump2'
cap_list_uri = URI('http://example.org/capability-list.xml')

parts = 1..3

zipfiles = []
at_times = []
completed_times = []

parts.each do |p|
  dir = "part#{p}"
  resources = ((p * 2 - 1)..(p * 2)).map do |r|
    file = "res#{r}"
    path = "#{dir}/#{file}"
    md5 = `md5 -q #{path}`.chop
    size = `wc -c #{path}`.chop.to_i
    Resync::Resource.new(
      uri: URI("http://example.org/#{file}"),
      modified_time: Time.utc(2015, 2, r),
      metadata: Resync::Metadata.new(
        hashes: { 'md5' => md5 },
        length: size,
        mime_type: MIME::Types['text/plain'].first,
        path: file
      )
    )
  end

  at_time = Time.utc(2015, 2, p * 2 - 1)
  completed_time = Time.utc(2015, 2, p * 2, 23, 59, 59)

  at_times << at_time
  completed_times << completed_time

  manifest = Resync::ResourceDumpManifest.new(
    resources: resources,
    links: [Resync::Link.new(rel: 'up', uri: cap_list_uri)],
    metadata: Resync::Metadata.new(
      at_time: at_time,
      completed_time: completed_time,
      capability: 'resourcedump-manifest'
    )
  )
  manifest_xml = manifest.save_to_xml

  manifest_file = "#{dir}/manifest.xml"
  File.open(manifest_file, 'w') do |f|
    f.puts('<?xml version="1.0" encoding="UTF-8"?>')
    formatter.write(manifest_xml, f)
    f.puts
  end

  files = resources.map { |r| "#{dir}/#{r.metadata.path}" }.join(' ')
  zipcmd = "zip -j #{dir}.zip #{manifest_file} #{files}"
  puts zipcmd
  `#{zipcmd}`

  zipfiles << "#{dir}.zip"
end

resources = []

zipfiles.each_with_index do |zf, i|
  md5 = `md5 -q #{zf}`.chop
  uri = URI("#{url_base}/#{zf}")
  size = `wc -c #{zf}`.chop.to_i
  resources << Resync::Resource.new(
    uri: uri,
    metadata: Resync::Metadata.new(
      mime_type: MIME::Types['application/zip'].first,
      length: size,
      at_time: at_times[i],
      completed_time: completed_times[i],
      hashes: { 'md5' => md5 }
    ),
    links: [
      Resync::Link.new(
        rel: 'contents',
        uri: URI("#{url_base}/part#{i + 1}/manifest.xml"),
        mime_type: MIME::Types['application/xml'].first
    )]
  )
end

resourcedump = Resync::ResourceDump.new(
  resources: resources,
  links: [Resync::Link.new(rel: 'up', uri: cap_list_uri)],
  metadata: Resync::Metadata.new(
    at_time: at_times[0],
    completed_time: completed_times[-1],
    capability: 'resourcedump'
  )
)
resourcedump_xml = resourcedump.save_to_xml

# formatter.write(resourcedump_xml, $stdout)

resourcedump_file = 'resourcedump2.xml'
File.open(resourcedump_file, 'w') do |f|
  f.puts('<?xml version="1.0" encoding="UTF-8"?>')
  formatter.write(resourcedump_xml, f)
  f.puts
end
