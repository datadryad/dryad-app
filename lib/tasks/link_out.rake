require_relative '../stash/link_out/helper'
require_relative '../stash/link_out/labslink_service'
require_relative '../stash/link_out/pubmed_sequence_service'
require_relative '../stash/link_out/pubmed_service'

namespace :link_out do

  desc 'Generate and then push the LinkOut file(s) to the LinkOut FTP servers'
  task publish: :environment do
    Rake::Task['link_out:create'].execute
    Rake::Task['link_out:push'].execute
  end

  desc 'Generate the LinkOut file(s)'
  task create: :environment do
    Rake::Task['link_out:create_pubmed_linkouts'].execute
    Rake::Task['link_out:create_labslink_linkouts'].execute
    Rake::Task['link_out:create_pubmed_sequence_linkouts'].execute
  end

  desc 'Generate the PubMed Link Out files'
  task create_pubmed_linkouts: :environment do
    create_link_out_dir!
    p "Generating LinkOut files for Pubmed #{Time.now.utc.strftime('%H:%m:%s')}"
    pubmed_service = LinkOut::PubmedService.new
    pubmed_service.generate_files!
    p "  finished at #{Time.now.utc.strftime('%H:%m:%s')}"
  end

  desc 'Generate the LabsLink LinkOut files'
  task create_labslink_linkouts: :environment do
    create_link_out_dir!
    p "Generating LinkOut files for LabLinks #{Time.now.utc.strftime('%H:%m:%s')}"
    labslink_service = LinkOut::LabslinkService.new
    labslink_service.generate_files!
    p "  finished at #{Time.now.utc.strftime('%H:%m:%s')}"
  end

  desc 'Generate the PubMed GenBank Sequence LinkOut files'
  task create_pubmed_sequence_linkouts: :environment do
    create_link_out_dir!
    p "Generating LinkOut files for GenBank #{Time.now.utc.strftime('%H:%m:%s')}"
    pubmed_sequence_service = LinkOut::PubmedSequenceService.new
    pubmed_sequence_service.generate_files!
    p "  finished at #{Time.now.utc.strftime('%H:%m:%s')}"
  end

  desc 'Push the LinkOut files to the LinkOut FTP servers'
  task push: :environment do
    p 'Publishing LinkOut files'
    p '  processing Pubmed files:'
    pubmed_service = LinkOut::PubmedService.new
    pubmed_service.publish_files! # if pubmed_service.validate_files!

    p '  processing GenBank files'
    pubmed_sequence_service = LinkOut::PubmedSequenceService.new
    pubmed_sequence_service.publish_files! # if pubmed_sequence_service.validate_files!

    p '  processing LabsLink files'
    labslink_service = LinkOut::LabslinkService.new
    labslink_service.publish_files! # if labslink_service.validate_files!
  end

  desc 'Seed existing datasets with PubMed Ids - This will query the API for each dataset created in the last year that has a cites DOI'
  task seed_pmids: :environment do
    p 'Retrieving Pubmed IDs for existing datasets'
    pubmed_service = LinkOut::PubmedService.new
    existing_pmids = StashEngine::Identifier.cited_by_pubmed.pluck(:id)
    resource_ids = StashEngine::Resource.latest_per_dataset.where.not(identifier_id: existing_pmids)
      .where('stash_engine_resources.created_at > ?', 1.year.ago).pluck(:id)
    related_identifiers = StashDatacite::RelatedIdentifier.where(resource_id: resource_ids, related_identifier_type: 'doi',
                                                                 work_type: 'primary_article').order(created_at: :desc)
    related_identifiers.each do |data|
      sleep(5) # The NCBI API has a threshold for how many times we can hit it
      rel_id = data.related_identifier
      rel_id = rel_id.gsub('https://doi.org/', '').gsub('doi:', '')
      p "  looking for pmid for #{rel_id}"
      pmid = pubmed_service.lookup_pubmed_id(rel_id)
      next unless pmid.present?

      internal_datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: data.resource.identifier_id, data_type: 'pubmedID')
      internal_datum.value = pmid.to_s
      next unless internal_datum.value_changed?

      p "    found pubmedID, '#{pmid}', ... attaching it to '#{data.related_identifier.gsub('doi:', '')}' " \
        "(identifier: #{data.resource.identifier_id})"
      internal_datum.save
    end
  end

  desc 'Seed existing datasets with GenBank Sequence Ids - this will query the API for each dataset created in the last year that has a pubmedID'
  task seed_genbank_ids: :environment do
    p 'Retrieving GenBank Sequence IDs for existing datasets'
    pubmed_sequence_service = LinkOut::PubmedSequenceService.new
    existing_refs = StashEngine::ExternalReference.all.pluck(:identifier_id).uniq
    existing_pmids = StashEngine::Identifier.cited_by_pubmed.where.not(id: existing_refs)
      .where('stash_engine_identifiers.created_at > ?', 1.year.ago).pluck(:id)
    datum = StashEngine::InternalDatum.where(identifier_id: existing_pmids, data_type: 'pubmedID').order(created_at: :desc)
    datum.each do |data|
      sleep(5) # The NCBI API has a threshold for how many times we can hit it
      p "  looking for genbank sequences for PubmedID #{data.value}"
      begin
        sequences = pubmed_sequence_service.lookup_genbank_sequences(data.value)
      rescue StandardError => e
        p "    ERROR: #{e.message} ... skipping update for #{data.identifier_id}, and pausing in case we hit a rate limiter"
        sleep(60)
        next
      end
      next unless sequences.any?

      sequences.each do |k, v|
        external_ref = StashEngine::ExternalReference.find_or_initialize_by(identifier_id: data.identifier_id, source: k)
        external_ref.value = v.to_s
        next unless external_ref.value_changed?

        p "    found #{v.length} identifiers for #{k}"
        begin
          external_ref.save
        rescue StandardError => e
          p "    ERROR: #{e.message} ... skipping update for #{data.identifier_id}"
          next
        end
      end
    end
  end

  desc 'Update Solr keywords with publication IDs'
  task seed_solr_keywords: :environment do
    p 'Updating Solr keywords with manuscriptNumber, pubmedID or a cites related identifier'
    types = %w[pubmedID manuscriptNumber cites]

    # rubocop:disable Layout/LineLength
    StashEngine::Identifier.joins(:internal_data).where("stash_engine_internal_data.data_type IN (?) AND stash_engine_internal_data.value IS NOT NULL AND stash_engine_internal_data.value != ''", types).each do |identifier|
      identifier.update_search_words!
      identifier.latest_resource.submit_to_solr
    end
    # rubocop:enable Layout/LineLength
  end

  def create_link_out_dir!
    Dir.mkdir("#{Dir.pwd}/tmp") unless Dir.exist?("#{Dir.pwd}/tmp")
    Dir.mkdir("#{Dir.pwd}/tmp/link_out") unless Dir.exist?("#{Dir.pwd}/tmp/link_out")
  end

end
