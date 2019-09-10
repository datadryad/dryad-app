# frozen_string_literal: true

require 'net/ftp'

require_relative 'helper'

module LinkOut

  # Every article in PubMed for which there are data in Dryad should have a link out to its
  # respective Dryad data package. Initially, this will be restricted to those PubMed articles
  # that also have a DOI (which should be the far majority of PubMed articles that have a
  # Dryad data package).
  class PubmedService

    include ::LinkOut::Helper

    attr_reader :provider_file
    attr_reader :links_file

    def initialize
      @pubmed_api = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi'
      @pubmed_api_query_prefix = 'db=pubmed&term='
      @pubmed_api_query_suffix = '[doi]'

      @ftp = APP_CONFIG.link_out.pubmed
      @root_url = Rails.application.routes.url_helpers.root_url.freeze

      @schema = 'https://www.ncbi.nlm.nih.gov/projects/linkout/doc/LinkOut.dtd'
      @links_file = 'pubmedlinkout.xml'
      @provider_file = 'providerinfo.xml'
    end

    # Retrieve the Pubmed ID for the specified DOI. See below for a sample of the expected XML response
    def lookup_pubmed_id(doi)
      return nil unless doi.present?
      query = "#{@pubmed_api_query_prefix}#{doi}#{@pubmed_api_query_suffix}"
      results = get_xml_from_api(@pubmed_api, query)
      return nil if results.blank?
      extract_pubmed_id(results)
    end

    def generate_files!
      p "  created #{generate_provider_file!}"
      p "  created #{generate_links_file!}"
    end

    def validate_files!
      p "    retrieving latest schema from: #{@schema}"
      local_schema = download_schema!(@schema)
      p '    Provider file passed validation check' if valid_xml?("#{TMP_DIR}/#{@provider_file}", local_schema)
      p '    Links file passed validation check' if valid_xml?("#{TMP_DIR}/#{@links_file}", local_schema)
    end

    def publish_files!
      p "    TODO: sending files to #{@ftp.ftp_host}"
      # ftp = Net::FTP.new(@ftp.ftp_host)
      # ftp.login(@ftp.ftp_username, @ftp.ftp_password)
      # ftp.chdir(@ftp.ftp_dir)
      # ftp.putbinaryfile(@provider_file)
      # ftp.putbinaryfile(@links_file)
      # ftp.close
    end

    private

    def generate_provider_file!
      # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
      doc = Nokogiri::XML(ActionView::Base.new('app/views')
        .render(
          file: 'link_out/pubmed_provider.xml.erb',
          locals: {
            id: @ftp.ftp_provider_id,
            abbreviation: @ftp.ftp_username,
            url: @root_url,
            name: 'Dryad Digital Repository',
            description: 'Dryad is a nonprofit organization and an international repository of data underlying scientific and medical publications.'
          }
        ), nil, 'UTF-8')
      doc.create_internal_subset('Provider', '-//NLM//DTD LinkOut 1.0//EN', @schema.split('/').last)
      File.write("#{TMP_DIR}/#{@provider_file}", doc.to_xml)
      "#{TMP_DIR}/#{@provider_file}"
    end

    def generate_links_file!
      identifiers = StashEngine::Identifier.cited_by_pubmed.map do |identifier|
        { doi: identifier.to_s, pubmed_id: identifier.internal_data.where(data_type: 'pubmedID').first.value }
      end

      # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
      doc = Nokogiri::XML(ActionView::Base.new('app/views')
        .render(
          file: 'link_out/pubmed_links.xml.erb',
          locals: {
            provider_id: @ftp.ftp_provider_id,
            database: 'PubMed',
            link_base: 'dryad.pubmed.',
            icon_url: "#{@root_url}images/DryadLogo-Button.png",
            callback_base: "#{@root_url}discover?",
            callback_rule: 'query=%22&lo.doi;%22',
            subject_type: 'supplemental materials',
            identifiers: identifiers
          }
        ), nil, 'UTF-8')

      doc.create_internal_subset('LinkSet', '-//NLM//DTD LinkOut 1.0//EN', @schema.split('/').last)
      File.write("#{TMP_DIR}/#{@links_file}", unencode_callback_ampersand(doc.to_xml))
      "#{TMP_DIR}/#{@links_file}"
    end

    # Expected XML Response from the NCBI API that returns Pubmed IDs for DOIs
    # <?xml version="1.0" encoding="UTF-8" ?>
    # <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
    # <eSearchResult>
    #   <Count>1</Count>
    #   <RetMax>1</RetMax>
    #   <RetStart>0</RetStart>
    #   <IdList>
    #     <Id>26028437</Id>
    #   </IdList>
    #   <TranslationSet/>
    #   <TranslationStack>
    #     <TermSet>
    #       <Term>10.1016/j.cub.2015.04.062[doi]</Term>
    #       <Field>doi</Field>
    #       <Count>1</Count>
    #       <Explode>N</Explode>
    #     </TermSet>
    #     <OP>GROUP</OP>
    #   </TranslationStack>
    #   <QueryTranslation>10.1016/j.cub.2015.04.062[doi]</QueryTranslation>
    # </eSearchResult>
    def extract_pubmed_id(xml)
      doc = Nokogiri::XML(xml)
      doc.xpath('eSearchResult//IdList//Id').first&.text
    end

    # Nokogiri and other libraries encode ampersands `&amp;`
    # https://github.com/sparklemotion/nokogiri/issues/1127
    #
    # The PubMed Linkout system though wants it to be unencoded `&` which technically makes the
    # XML document invalid so we need to swap the `&` for `&amp;` after doing our Nokogiri `doc.to_xml`
    def unencode_callback_ampersand(text)
      text.gsub(/query\=%22&amp;lo\.doi;%22/, 'query=%22&lo.doi;%22')
    end

  end

end
