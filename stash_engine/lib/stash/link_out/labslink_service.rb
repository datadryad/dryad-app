# frozen_string_literal: true

require 'net/ftp'

require_relative 'helper'

module LinkOut

  # Dryad also furnishes links to Europe PMC via the LabsLink service. They support a
  # similar mechanism to NCBI LinkOut, where we provide a list of PMIDs and destination
  # data packages.
  #   Europe PMC LabsLink: http://europepmc.org/LabsLink
  class LabslinkService

    include ::LinkOut::Helper

    def initialize
      make_linkout_dir!
      @ftp = APP_CONFIG.link_out.labslink
      @schema = 'http://europepmc.org/docs/labslink.xsd'.freeze
      @links_file = 'labslink-links.xml'.freeze
      @doi_url_stem = 'http://dx.doi.org/'.freeze
      @provider_file = 'labslink-profile.xml'.freeze
      @root_url = Rails.application.routes.url_helpers.root_url.freeze
    end

    def generate_files!
      p "  created #{generate_provider_file!}"
      p "  created #{generate_links_file!}"
    end

    def validate_files!

    end

    def publish_files!

    end

    private

    def generate_provider_file!
      # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
      doc = Nokogiri::XML(ActionView::Base.new('app/views')
        .render(
          file: 'link_out/labslink_provider.xml.erb',
          locals: {
            id: @ftp.ftp_provider_id,
            name: 'Dryad Digital Repository',
            description: 'Dryad is a nonprofit organization and an international repository of data underlying scientific and medical publications.',
            email: 'linkout@datadryad.org'
          }
        ), nil, 'UTF-8')
      File.write("#{TMP_DIR}/#{@provider_file}", doc.to_xml)
      "#{TMP_DIR}/#{@provider_file}"
    end

    def generate_links_file!
      identifiers = StashEngine::Identifier.cited_by_pubmed

      # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
      doc = Nokogiri::XML(ActionView::Base.new('app/views')
        .render(
          file: 'link_out/labslink_links.xml.erb',
          locals: {
            provider_id: @ftp.ftp_provider_id,
            database: 'MED',
            show_url_base: @doi_url_stem,
            identifiers: identifiers
          }
        ), nil, 'UTF-8')
      File.write("#{TMP_DIR}/#{@links_file}", doc.to_xml)
      "#{TMP_DIR}/#{@links_file}"
    end

  end

end
