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

    def initialize
      make_linkout_dir!

      @ftp = APP_CONFIG.link_out.ncbi_pubmed
      @schema = 'http://www.ncbi.nlm.nih.gov/entrez/linkout/doc/LinkOut.dtd'.freeze
      @links_file = 'pubmedlinkout.xml'.freeze
      @provider_file = 'providerinfo.xml'.freeze
      @root_url = Rails.application.routes.url_helpers.root_url.freeze
    end

    def generate_files!
      p "  created #{generate_provider_file!}"
      p "  created #{generate_links_file!}"
    end

    def validate_files!
      local_schema = download_schema(schema)
      # Do the appropriate validation based on the file type
      p "    Provider file passed validation check" if valid_xml?(@provider_file)
      p "    Links file passed validation check" if valid_xml?(@links_file)
    end

    def publish_files!
      p "    TODO: sending files to #{@ftp.ftp_host}"
      #ftp = Net::FTP.new(@ftp.ftp_host)
      #ftp.login(@ftp.ftp_username, @ftp.ftp_password)
      #ftp.chdir(@ftp.ftp_dir)
      #ftp.putbinaryfile(@provider_file)
      #ftp.putbinaryfile(@links_file)
      #ftp.close
    end

    private

    def generate_provider_file!
      doc = Nokogiri::XML(ActionView::Base.new('app/views')
        .render(
          file: "link_out/#{@provider_file}.erb",
          locals: {
            id: @ftp.ftp_provider_id,
            abbreviation: @ftp.ftp_username,
            url: @root_url,
            name: 'Dryad Digital Repository',
            description: 'Dryad is a nonprofit organization and an international repository of data underlying scientific and medical publications.',
          }
        ), nil, 'UTF-8')
      doc.create_external_subset('Provider', '-//NLM//DTD LinkOut 1.0//EN', @schema)
      File.write("#{TMP_DIR}/#{@provider_file}", doc.to_xml)
      "#{TMP_DIR}/#{@provider_file}"
    end

    def generate_links_file!
      identifiers = StashEngine::Identifier.cited_by_pubmed.map do |identifier|
        { doi: identifier.to_s, pubmed_id: identifier.internal_data.where(data_type: 'pubmedID').first.value }
      end

      doc = Nokogiri::XML(ActionView::Base.new('app/views')
        .render(
          file: "link_out/#{@links_file}.erb",
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

      doc.create_external_subset('LinkSet', '-//NLM//DTD LinkOut 1.0//EN', @schema)
      File.write("#{TMP_DIR}/#{@links_file}", doc.to_xml)
      "#{TMP_DIR}/#{@links_file}"
    end

  end

end
