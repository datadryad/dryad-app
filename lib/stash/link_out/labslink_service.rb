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

      attr_reader :provider_file, :links_file_format

      MAX_FILE_SIZE = 9 * 1024 * 1024 # 9 MB

      def initialize
        @ftp = APP_CONFIG.link_out.labslink
        @schema = 'http://europepmc.org/docs/labslink.xsd'
        @links_file_format = 'labslink-links[nbr].xml'
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
        Dir["#{TMP_DIR}/#{links_file_format.gsub('[nbr]', '*')}"].entries.each do |file|
          p '    Links file passed validation check' if valid_xml?("#{TMP_DIR}/#{File.basename(file)}", local_schema)
        end
        p '    Links file passed validation check' if valid_xml?("#{TMP_DIR}/#{@links_file}", local_schema)
      end

      def publish_files!
        p '  pushing files to PubMed FTP server'
        ftp = Net::FTP.new(@ftp.ftp_host)
        ftp.login(@ftp.ftp_username, @ftp.ftp_password)
        ftp.chdir(@ftp.ftp_dir)
        ftp.putbinaryfile("#{TMP_DIR}/#{@provider_file}")
        Dir["#{TMP_DIR}/#{links_file_format.gsub('[nbr]', '*')}"].entries.each do |file|
          ftp.putbinaryfile("#{TMP_DIR}/#{File.basename(file)}")
        end
        ftp.close
      rescue StandardError => e
        p "    FTP Error: #{e.message}"
      end

      private

      def generate_provider_file!
        # Note that the view referenced below lives in the Dryad repo in the dryad/app/views dir
        doc = Nokogiri::XML(ActionView::Base.with_empty_template_cache.new(ActionView::LookupContext.new('app/views'), {}, nil)
          .render(
            template: 'link_out/labslink_provider',
            format: :xml,
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
        @file_names = []
        identifiers = StashEngine::Identifier.cited_by_pubmed
        file_index = 1
        current_file_size = 0
        file = new_xml_file(file_index)
        start_xml_file(file)

        identifiers.each do |identifier|
          record_xml = generate_xml_link(identifier)
          record_size = record_xml.bytesize

          if current_file_size + record_size > MAX_FILE_SIZE
            # close the current file
            close_xml_file(file)

            # start a new file
            file_index += 1
            current_file_size = 0
            file = new_xml_file(file_index)
            start_xml_file(file)
          end

          file.write(record_xml)
          current_file_size += record_size
        end
        close_xml_file(file)

        @file_names.join(', ')
      end

      def new_xml_file(file_index)
        file_name = "#{TMP_DIR}/#{links_file_format.gsub('[nbr]', "-#{file_index}")}"
        @file_names << file_name

        File.open(file_name, 'w')
      end

      def generate_xml_link(identifier)
        doc = Nokogiri::XML(ActionView::Base.with_empty_template_cache.new(ActionView::LookupContext.new('app/views'), {}, nil)
          .render(
            template: 'link_out/labslink_link',
            format: :xml,
            locals: {
              provider_id: @ftp.ftp_provider_id,
              database: 'MED',
              show_url_base: @doi_url_stem,
              identifier: identifier
            }
          ), nil, 'UTF-8')
        doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
      end

      def start_xml_file(file)
        file.puts('<?xml version="1.0" encoding="UTF-8"?>')
        file.puts('<!-- Dryad LinkOut Links file for European PubMed Central LabsLink -->')
        file.puts('<links>')
      end

      def close_xml_file(file)
        file.puts('</links>')
        file.close
      end
    end
  end
end
