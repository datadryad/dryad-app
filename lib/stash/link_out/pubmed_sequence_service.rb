# frozen_string_literal: true

require 'net/sftp'

module Stash
  module LinkOut

    # Every sequence record in NCBI databases with LinkOut capabilities that has an article as
    # reference (REFERENCE line in GenBank format) for which there is a data package in Dryad
    # should have a link out to the respective data package. Initially this may be restricted
    # to the nucleotide databases (and here to the NUCCORE database), which should, however,
    # be the most common use-case, and may also need to be restricted to sequences for those
    # articles that also have a DOI.
    class PubmedSequenceService

      include Stash::LinkOut::Helper

      attr_reader :links_file

      def initialize
        @genbank_api = 'https://www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi'

        @ftp = APP_CONFIG.link_out.pubmed
        @root_url = root_url_ssl
        @file_counter = 1

        @schema = 'https://www.ncbi.nlm.nih.gov/projects/linkout/doc/LinkOut.dtd'
        @links_file = 'sequencelinkout[nbr].xml'
        @max_nodes_per_file = 50_000
      end

      # Retrieve the GenBank Database ID(s) for the specified PubMedId. See below for a sample of the expected XML response
      def lookup_genbank_sequences(pmid)
        return nil unless pmid.present?

        hash = {}
        StashEngine::ExternalReference.sources.each do |db|
          query = "dbfrom=pubmed&db=#{db}&id=#{pmid}&api_key=#{@ftp.api_key}"
          genbank_ids = extract_genbank_ids(get_xml_from_api(@genbank_api, query))
          hash[db] = genbank_ids unless genbank_ids.empty?
        end
        hash
      end

      def generate_files!
        p "  created #{generate_links_file!}"
      end

      def validate_files!
        p "    retrieving latest schema from: #{@schema}"
        local_schema = download_schema!(@schema)
        Dir["#{TMP_DIR}/#{@provider_file}/#{@links_file.gsub('[nbr]', '*')}"].entries.each do |file|
          p "    Sequence file #{file} passed validation check" if valid_xml?(file, local_schema)
        end
      end

      def publish_files!
        Net::SFTP.start(@ftp.ftp_host, @ftp.ftp_username, password: @ftp.ftp_password) do |sftp|
          Dir["#{TMP_DIR}/#{@links_file.gsub('[nbr]', '*')}"].entries.each do |file|
            sftp.upload!(file.to_s, "#{@ftp.ftp_dir}/#{File.basename(file)}")
          end
        rescue Net::SFTP::StatusException => e
          p "    SFTP Error: #{e.message}"
        end
      end

      private

      def generate_provider_file!
        # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
      end

      def generate_links_file!
        doc = start_sequence_file

        StashEngine::ExternalReference.sources.each do |db|
          identifiers = StashEngine::Identifier.cited_by_external_site(db).map do |identifier|
            {
              doi: identifier.to_s,
              sequence: identifier.external_references.where(source: db).first.value
            }
          end

          # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
          identifiers.each_with_index do |hash, idx|
            doc.xpath('LinkSet').first << generate_fragment(idx, db, hash)
            next unless reached_max_file_size?(doc)

            finish_sequence_file(doc)
            doc = start_sequence_file
          end
        end

        finish_sequence_file(doc)
        "#{TMP_DIR}/#{@links_file} - #{@file_counter - 1} file(s)"
      end

      def start_sequence_file
        doc = Nokogiri::XML(<<~XML
          <!-- Dryad LinkOut Links file for Pubmed GenBank Sequence -->
          <LinkSet></LinkSet>
        XML
                           )
        doc.create_internal_subset('LinkSet', '-//NLM//DTD LinkOut 1.0//EN', @schema.split('/').last)
        doc
      end

      def finish_sequence_file(doc)
        File.write("#{TMP_DIR}/#{@links_file.gsub('[nbr]', @file_counter.to_s.rjust(6, '0'))}", doc.to_xml)
        @file_counter += 1
      end

      def reached_max_file_size?(doc)
        return false if doc.xpath('.//*').size < @max_nodes_per_file

        true
      end

      def generate_fragment(idx, db, hash)
        Nokogiri::XML.fragment(ActionView::Base.new(ActionView::LookupContext.new('app/views'), {}, nil)
          .render(
            file: Rails.root.join('app', 'views', 'link_out', 'sequence_links.xml.erb'),
            locals: {
              counter: idx,
              provider_id: @ftp.ftp_provider_id,
              database: db,
              link_base: 'dryad.seq.',
              icon_url: "#{@root_url}images/DryadLogo-Button.png",
              callback_base: "#{@root_url}stash/dataset/",
              callback_rule: hash[:doi],
              subject_type: 'supplemental materials',
              ids: JSON.parse(hash[:sequence])
            }
          ))
      end

      # Expected XML Response from the NCBI API that returns Database IDs for PubMed IDs
      # <?xml version="1.0" encoding="UTF-8" ?>
      # <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
      # <eLinkResult>
      #   <LinkSet>
      #     <DbFrom>pubmed</DbFrom>
      #     <IdList>
      #       <Id>21166729</Id>
      #     </IdList>
      #     <LinkSetDb>
      #       <DbTo>nuccore</DbTo>
      #       <LinkName>pubmed_nuccore</LinkName>
      #       <Link>
      #         <Id>316925971</Id>
      #       </Link>
      #       <Link>
      #         <Id>316925605</Id>
      #       </Link>
      #     </LinkSetDb>
      #   </LinkSet>
      # </eLinkResult>
      def extract_genbank_ids(xml)
        doc = Nokogiri::XML(xml)
        return [] unless doc.xpath('eLinkResult//LinkSet//LinkSetDb').first.present?

        doc.xpath('eLinkResult//LinkSet//LinkSetDb/Link/Id').map { |id| id&.text }.uniq.reject { |id| id == '0' }
      end

    end

  end
end
