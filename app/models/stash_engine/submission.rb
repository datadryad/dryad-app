require 'stash/sword'

Stash::Sword::CommandLine.exec(ARGV) do |client, options|
  zipfile = options.zipfile
  fail 'no zipfile provided' unless zipfile
  fail "#{zipfile} does not exist" unless File.exist?(zipfile)
  fail "#{zipfile} is not a file" unless File.file?(zipfile)
  fail "Unable to read #{zipfile}" unless File.readable?(zipfile)

  doi = options.doi
  fail 'no DOI provided' unless doi

  collection_uri = options.collection_uri
  fail 'no Collection URI provided' unless collection_uri

  edit_iri = nil
  result = client.post_create(collection_uri: collection_uri, slug: doi, zipfile: zipfile) do |response, request, result, &block|
    if [301, 302, 307].include? response.code
      response.follow_redirection(request, result, &block)
    else
      res = response.net_http_res
      puts "HTTP #{res.code} #{res.msg}\n"
      res.each do |k, v|
        if k.downcase == 'location'
          edit_iri = v
        end
        puts "#{k} = #{v}"
      end
      if res.class.body_permitted?
        puts "\n"
        puts res.body
      end
      response.return!(request, result, &block)
    end
  end

  entry = Atom::Entry.parse(result)
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

  if edit_iri
    puts "Edit-IRI: #{edit_iri}"
  end
end