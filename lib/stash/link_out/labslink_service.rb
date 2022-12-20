# frozen_string_literal: true

require 'net/ftp'

module Stash
  module LinkOut

    # Dryad also furnishes links to Europe PMC via the LabsLink service. They support a
    # similar mechanism to NCBI LinkOut, where we provide a list of PMIDs and destination
    # data packages.
    #   Europe PMC LabsLink: http://europepmc.org/LabsLink
    class LabslinkService

      include Stash::LinkOut::Helper

      attr_reader :provider_file, :links_file

      def initialize
        @ftp = APP_CONFIG.link_out.labslink
        @schema = 'http://europepmc.org/docs/labslink.xsd'
        @links_file = 'labslink-links.xml'
        @doi_url_stem = 'http://dx.doi.org/'
        @provider_file = 'labslink-profile.xml'
        @root_url = root_url_ssl
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
        ftp = Net::FTP.new(@ftp.ftp_host)
        ftp.login(@ftp.ftp_username, @ftp.ftp_password)
        ftp.chdir(@ftp.ftp_dir)
        ftp.putbinaryfile("#{TMP_DIR}/#{@provider_file}")
        ftp.putbinaryfile("#{TMP_DIR}/#{@links_file}")
        ftp.close
      rescue StandardError => e
        p "    FTP Error: #{e.message}"
      end

      private

      def generate_provider_file!
        # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
        doc = Nokogiri::XML(ActionView::Base.with_empty_template_cache.new(ActionView::LookupContext.new('app/views'), {}, nil)
          .render(
            template: 'link_out/labslink_provider.xml.erb',
            locals: {
              id: @ftp.ftp_provider_id,
              name: 'Dryad Data Platform',
              description:
                'Dryad is a nonprofit organization and an international repository of data underlying scientific and medical publications.',
              email: 'linkout@datadryad.org'
            }
          ), nil, 'UTF-8')
        File.write("#{TMP_DIR}/#{@provider_file}", doc.to_xml)
        "#{TMP_DIR}/#{@provider_file}"
      end

      def generate_links_file!
        identifiers = StashEngine::Identifier.cited_by_pubmed

        # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
        doc = Nokogiri::XML(ActionView::Base.with_empty_template_cache.new(ActionView::LookupContext.new('app/views'), {}, nil)
          .render(
            template: 'link_out/labslink_links.xml.erb',
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
end
