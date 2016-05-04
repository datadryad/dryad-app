#! /usr/bin/env ruby

require 'stash/sword'

Stash::Sword::CommandLine.exec(ARGV) do |client, options|
  zipfile = options.zipfile
  raise 'no zipfile provided' unless zipfile
  raise "#{zipfile} does not exist" unless File.exist?(zipfile)
  raise "#{zipfile} is not a file" unless File.file?(zipfile)
  raise "Unable to read #{zipfile}" unless File.readable?(zipfile)

  doi = options.doi
  raise 'no DOI provided' unless doi

  collection_uri = options.collection_uri
  raise 'no Collection URI provided' unless collection_uri

  edit_iri = nil
  res = client.post_create(collection_uri: collection_uri, slug: doi, zipfile: zipfile) do |response, request, result, &block|
    if [301, 302, 307].include? response.code
      response.follow_redirection(request, result, &block)
    else
      result = response.net_http_res
      puts "HTTP #{result.code} #{result.msg}\n"
      result.each do |k, v|
        edit_iri = v if k.casecmp('location').zero?
        puts "#{k} = #{v}"
      end
      if result.class.body_permitted?
        puts "\n"
        puts result.body
      end
      response.return!(request, result, &block)
    end
  end

  entry = Atom::Entry.parse(res)
  if entry
    puts "\n"
    entry.edit_media_links.each do |link|
      puts "EM-IRI:  #{link.href}"
    end

    se_uri = entry.sword_edit_uri
    puts "SE-IRI:  #{se_uri}" if se_uri

    content = entry.content
    puts "Cont-IRI: #{content.src}" if content
  else
    $stderr.puts 'Deposit did not return an entry'
  end

  puts "Edit-IRI: #{edit_iri}" if edit_iri
end
