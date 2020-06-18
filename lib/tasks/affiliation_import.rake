# -*- coding: utf-8 -*-
require 'csv'



namespace :affiliation_import do

  ROOT = Rails.root.join('/tmp').freeze

  desc 'Process all of the TSV files'
  task process_ror_csv: :environment do
    start_time = Time.now
    @dois_to_skip = []
    @live_mode = false

    case ENV['AFFILIATION_MODE']
    when nil
      puts 'Environment variable AFFILIATION_MODE is blank, assuming test mode.'
    when 'live'
      puts 'Starting live processing due to environment variable AFFILIATION_MODE.'
      @live_mode = true
    else
      puts "Environment variable AFFILIATION_MODE is #{ENV['AFFILIATION_MODE']}, entering test mode."
    end
    
    puts 'Loading affiliation info from CSV files in /tmp/dryad_affiliations*'
    
    Dir.entries(ROOT).each do |f|
      next unless f.start_with?('dryad_affiliations')
      qualified_file_name = "#{ROOT}/#{f}"
      puts "===== Processing file #{qualified_file_name} ====="
      process_file(file_name: qualified_file_name)
    end

    puts "DONE! Elapsed time: #{Time.at(Time.now - start_time).utc.strftime("%H:%M:%S")}"
  end

  def process_file(file_name:)
    CSV.foreach(file_name) do |entry|
      #puts "<< #{entry} >>"
      next if entry[0] == 'DOI' && entry[1] == 'person' # header row

      doi, person, organization, ror_original, ror, identifier_date, supplement_to, \
      publication_date, title, type, update_date, organization_date = entry
      
      next if @dois_to_skip.include?(doi)
      next unless doi.present?
      identifier = StashEngine::Identifier.where(identifier: doi).first
      @dois_to_skip << doi unless identifier.present?
      puts "****** NO DATASET FOUND WITH ID: #{doi} -- #{title}" unless identifier.present?
      next unless identifier.present?
      next unless identifier.latest_resource.present?
      puts "Processing #{identifier.to_s} #{title}"
      handle_author(resource: identifier.latest_resource, name: person, ror: ror, org_name: organization)
    end
  end

  def handle_author(resource:, name:, ror:, org_name:)
    return nil unless resource.present? && name.present?
    
    # start with the assuption that the firstname lastname split is at the first space
    parts = name.split(' ')
    first = parts[0]
    last = parts[1..-1].join(' ')
    puts "searching authors for resource #{resource.id}, first[#{first}], last[#{last}]"
    author = StashEngine::Author.where('stash_engine_authors.resource_id = ? AND LOWER(stash_engine_authors.author_last_name) = ? AND LOWER(stash_engine_authors.author_first_name) = ?', resource.id, last, first).first

    if author.nil? && parts.size > 2
      # try split at second space, see if we find an author that way
      first = parts[0..1].join(' ')
      last = parts[2..-1].join(' ')
      puts "searching authors for resource #{resource.id}, first[#{first}], last[#{last}]"
      author = StashEngine::Author.where('stash_engine_authors.resource_id = ? AND LOWER(stash_engine_authors.author_last_name) = ? AND LOWER(stash_engine_authors.author_first_name) = ?', resource.id, last, first).first
    end
    
    if author.blank?
      puts "    Creating new author: #{author.author_last_name}, #{author.author_first_name}"
      if @live_mode
        author = StashEngine::Author.new(resource_id: resource.id, author_last_name: last, author_first_name: first)
        author.save
      end
    end
    handle_affiliation(author: author, ror: ror, org_name: org_name)
  end

  def handle_affiliation(author:, ror:, org_name:)
    # what does brian's code do?
    # - find an existing affiliation (twice?)
    # - add it to the author
    # what do I want my code to do?
    # - If there is a difference between the ror and the existing item
    #   ROR, and the item is pre-launch, update it
    # - If there is no ror in the item, add it (either by ror or by the long_name)

    return nil unless author.present? && org_name.present?
    affiliation = StashDatacite::Affiliation.where('dcs_affiliations.ror_id = ? OR dcs_affiliations.long_name = ?',
      ror, org_name).first

    puts "    Assigning affiliation: #{affiliation.long_name} --> #{affiliation.ror_id}"
    if @live_mode
      affiliation = StashDatacite::Affiliation.find_or_initialize_by(long_name: org_name, ror_id: ror)
      affiliation.authors << author
      affiliation.save
    end
  end
end
