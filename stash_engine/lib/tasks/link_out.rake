require_relative '../stash/link_out/helper'
require_relative '../stash/link_out/labslink_service'
require_relative '../stash/link_out/pubmed_sequence_service'
require_relative '../stash/link_out/pubmed_service'

# rubocop:disable Metrics/BlockLength
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
    p "Generating LinkOut files for Pubmed #{Time.now.strftime('%H:%m:%s')}"
    pubmed_service = LinkOut::PubmedService.new
    pubmed_service.generate_files!
    p "  finished at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Generate the LabsLink LinkOut files'
  task create_labslink_linkouts: :environment do
    p "Generating LinkOut files for LabLinks #{Time.now.strftime('%H:%m:%s')}"
    labslink_service = LinkOut::LabslinkService.new
    labslink_service.generate_files!
    p "  finished at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Generate the PubMed GenBank Sequence LinkOut files'
  task create_pubmed_sequence_linkouts: :environment do
    p "Generating LinkOut files for GenBank #{Time.now.strftime('%H:%m:%s')}"
    pubmed_sequence_service = LinkOut::PubmedSequenceService.new
    pubmed_sequence_service.generate_files!
    p "  finished at #{Time.now.strftime('%H:%m:%s')}"
  end

  desc 'Push the LinkOut files to the LinkOut FTP servers'
  task push: :environment do
    p "Publishing LinkOut files"
    p "  processing Pubmed files:"
    pubmed_service = LinkOut::PubmedService.new
    pubmed_service.publish_files! if pubmed_service.validate_files!

    p "  processing GenBank files"
    pubmed_sequence_service = LinkOut::PubmedSequenceService.new
    pubmed_sequence_service.publish_files! if pubmed_sequence_service.validate_files!

    p "  processing LabsLink files"
    labslink_service = LinkOut::LabslinkService.new
    labslink_service.publish_files! if labslink_service.validate_files!
  end

  desc 'Seed existing datasets with PubMed Ids - WARNING: this will query the API for each dataset that has a publicationDOI!'
  task seed_pmids: :environment do
    p "Retrieving Pubmed IDs for existing datasets"
    pubmed_service = LinkOut::PubmedService.new
    existing_pmids = StashEngine::Identifier.cited_by_pubmed.pluck(:id)
    datum = StashEngine::InternalDatum.where.not(identifier_id: existing_pmids).where(data_type: 'publicationDOI').order(created_at: :desc)
    datum.each do |data|
      p "  looking for pmid for #{data.value}"
      pmid = pubmed_service.lookup_pubmed_id(data.value.gsub('doi:', ''))
      next unless pmid.present?

      internal_datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: data.identifier_id, data_type: 'pubmedID')
      internal_datum.value = pmid.to_s
      next unless internal_datum.value_changed?

      p "    found pubmedID, '#{pmid}', ... attaching it to '#{data.value.gsub('doi:', '')}' (identifier: #{data.identifier_id})"
      internal_datum.save
      sleep(1)
    end
  end

  desc 'Seed existing datasets with GenBank Sequence Ids - WARNING: this will query the API for each dataset that has a pubmedID!'
  task seed_genbank_ids: :environment do
    p "Retrieving GenBank Sequence IDs for existing datasets"
    pubmed_sequence_service = LinkOut::PubmedSequenceService.new
    existing_pmids = StashEngine::Identifier.cited_by_pubmed.pluck(:id)
    datum = StashEngine::InternalDatum.where(identifier_id: existing_pmids, data_type: 'pubmedID').limit(30).order(created_at: :desc)
    datum.each do |data|
      p "  looking for genbank sequences for PubmedID #{data.value}"
      sequences = pubmed_sequence_service.lookup_genbank_sequences(data.value)
      next unless sequences.any?

      sequences.each do |k, v|
        external_ref = StashEngine::ExternalReference.find_or_initialize_by(identifier_id: data.identifier_id, source: k)
        external_ref.value = v.to_s
        next unless external_ref.value_changed?

        p "    found #{v.length} identifiers for #{k}"
        external_ref.save
      end
      sleep(1)  # The NCBI API has a threshold for how many times we can hit it
    end
  end

end
# rubocop:enable Metrics/BlockLength
