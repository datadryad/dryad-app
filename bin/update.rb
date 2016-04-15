#! /usr/bin/env ruby

require 'stash/sword'

Stash::Sword::CommandLine.exec(ARGV) do |client, options|
  zipfile = options.zipfile
  fail 'no zipfile provided' unless zipfile
  fail "#{zipfile} does not exist" unless File.exist?(zipfile)
  fail "#{zipfile} is not a file" unless File.file?(zipfile)
  fail "Unable to read #{zipfile}" unless File.readable?(zipfile)

  doi = options.doi
  fail 'no DOI provided' unless doi

  edit_iri = options.edit_iri
  fail 'no Edit-IRI provided' unless edit_iri
  warn 'Merrit Edit-IRI should end with DOI' unless edit_iri.end_with?(doi)

  res = client.put_update(edit_iri: edit_iri, slug: doi, new_zipfile: zipfile)
  if res.is_a?(Net::HTTPResponse)
    puts "HTTP #{res.code} #{res.msg}\n"
    res.each do |k, v|
      puts "#{k} = #{v}"
    end
    if res.class.body_permitted?
      puts "\n"
      puts res.body
    end
  end
end
