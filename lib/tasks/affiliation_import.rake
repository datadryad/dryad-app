# -*- coding: utf-8 -*-
require 'csv'

namespace :affiliation_import do

  ROOT = Rails.root.join('tmp', 'Results').freeze

  desc 'Process all of the TSV files'
  task process_ror_tsv: :environment do
    start_time = Time.now
    p "Loading Journal, Author and Affiliation info from TSV files in tmp/Results"

    crosswalk = CSV.read("#{ROOT}/Crosswalk.csv", headers: true)

    entries = []
    dois_to_skip = []
    Dir.entries(ROOT).each do |f|
      next unless f.end_with?('.tsv')

      qualified_file_name = "#{ROOT}/#{f}"
      entries += read_tsv_file(file_name: qualified_file_name).select do |row|
        row['selected']&.downcase == 'true' && row['tokenIndex'] == '1'
      end
    end
    p "Found #{entries.length} entries to process."

    curr_doi = ''
    entries.map do |entry|
      next if dois_to_skip.include?(entry['DOI'])
      matched = crosswalk.select { |cw| cw['ArticleDOI']&.gsub('doi:', '') == entry['DOI']&.gsub('doi:', '') }.first
      next unless entry['DOI'].present? && matched.present?

      identifier = StashEngine::Identifier.where("stash_engine_identifiers.identifier like ?", "%#{matched['PackageDOI'].gsub('doi:', '')}").first
      dois_to_skip << entry['DOI'] unless identifier.present?
      p "****** NO MATCH FOR: (#{entry['DOI']}) #{entry['title']}" unless identifier.present?
      next unless identifier.present?

      p "Matched: #{entry['title']} -- Journal DOI: #{entry['DOI']} => Dataset DOI: #{identifier.to_s}" unless curr_doi == entry['DOI']
      curr_doi = entry['DOI']
      handle_journal_name(identifier: identifier, hash: entry)
      handle_journal_doi(identifier: identifier, hash: entry)

      next unless identifier.latest_resource.present?
      handle_author(resource: identifier.latest_resource, hash: entry)
    end
    p "DONE! Elapsed time: #{(Time.now - start_time).strftime('%H:%M:%S')}"
  end

  def handle_author(resource:, hash:)
    return nil unless resource.present? && hash['family'].present?
    author = StashEngine::Author.where('stash_engine_authors.resource_id = ? AND LOWER(stash_engine_authors.author_last_name) = ? AND LOWER(stash_engine_authors.author_first_name) = ?',
      resource.id, hash['family'], hash['given']).first
    author = StashEngine::Author.new(resource_id: resource.id, author_last_name: hash['family'], author_first_name: hash['given']) unless author.present?
    p "    Assigning author: #{author.author_last_name}, #{author.author_first_name}"
    author.save
    handle_affiliation(author: author, hash: hash)
  end

  def handle_affiliation(author:, hash:)
    return nil unless author.present? && hash['organizationLookupName'].present?
    affiliation = StashDatacite::Affiliation.where('dcs_affiliations.ror_id = ? OR dcs_affiliations.long_name = ?',
      hash['ROR'], hash['organizationLookupName']).first
    affiliation = StashDatacite::Affiliation.find_or_initialize_by(long_name: hash['organizationLookupName'], ror_id: hash['ROR'])
    p "    Assigning affiliation: #{affiliation.long_name} --> #{affiliation.ror_id}"
    affiliation.authors << author
    affiliation.save
  end

  def handle_journal_name(identifier:, hash:)
    return nil unless identifier.present? && hash['journal'].present?
    datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: identifier.id, data_type: 'publicationName')
    datum.value = hash['journal']
    p "    Assigning Journal: '#{datum.value}'" if datum.value&.include?('�')
    datum.save
  end

  def handle_journal_doi(identifier:, hash:)
    return nil unless identifier.present? && hash['DOI'].present?
    datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: identifier.id, data_type: 'publicationDOI')
    datum.value = hash['DOI']
    p "    Assigning Journal DOI: '#{datum.value}'"
    datum.save if hash['DOI']
  end

  def read_tsv_file(file_name:)
    params = {
      col_sep: "\t",
      headers: true,
      encoding: "utf-8"
    }
    return nil unless File.exists?(file_name)
    CSV.read(file_name, params.merge({ quote_char: '^' }))

  rescue CSV::MalformedCSVError
    begin
      CSV.read(file_name, params.merge({ quote_char: '|' }))

    rescue CSV::MalformedCSVError
      begin
        CSV.read(file_name, params.merge({ quote_char: '~' }))

      rescue CSV::MalformedCSVError
        CSV.read(file_name, params.merge({ quote_char: '@' }))
      end
    end
  end

end
