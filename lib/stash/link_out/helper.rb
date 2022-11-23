# frozen_string_literal: true

require 'httparty'
require 'net/ftp'
require 'zlib'

module Stash
  module LinkOut

    # This helper class provides common methods used by all of the LinkOut services
    module Helper
      TMP_DIR = "#{Rails.root}/tmp/link_out".freeze

      def root_url_ssl
        Rails.application.routes.url_helpers.root_url.gsub(/^http:/, 'https:')
      end

      def request_headers
        {
          'User-Agent': 'datadryad.org (contact: help@datadryad.org)',
          Accept: 'text/xml'
        }
      end

      # Retrieve the XML from the API (e.g. lookup Pubmed ID for a given DOI)
      def get_xml_from_api(uri, query)
        resp = HTTParty.get(uri, query: query, headers: request_headers)
        # If we received anything but a 200 then log an error and return an empty array
        raise "Unable to connect to connect to - #{@pubmed_api}?#{query}: status: #{resp.code}" if resp.code != 200
        # Return an empty array if the response did not have any results
        return nil if resp.code != 200 || resp.blank?

        resp.body
      end

      # Download the specified XML schema to the local TMP_DIR
      def download_schema!(uri)
        file_name = "#{TMP_DIR}/#{uri.split('/').last}"
        File.write(file_name, HTTParty.get(uri).body)
        file_name
      end

      # Gzip the specified file
      def compress_file!(file_name)
        zipped = "#{file_name}.gz"
        Zlib::GzipWriter.open(zipped) do |gz|
          gz.mtime = File.mtime(file_name)
          gz.orig_name = file_name
          gz.write File.binread(file_name)
        end
        p "    compressing (gzip) #{file_name} - before: #{File.size(file_name)} after: #{File.size(zipped)}"
        zipped
      end

      # Validate the XML document against the Schema
      def valid_xml?(file_name, schema)
        # Do the appropriate validation based on the file type
        return validate_against_xsd(file_name, schema) if schema.downcase.ends_with?('.xsd')

        validate_against_dtd(file_name, schema)
      end

      private

      def validate_against_xsd(xml_file, xsd_file)
        xsd = Nokogiri::XML::Schema(File.read(xsd_file))
        doc = Nokogiri::XML(File.read(xml_file))
        return true if xsd.valid?(doc)

        p "      ERROR! #{xml_file} does not conform to the XML schema defined in: #{xsd_file}:"
        xsd.validate(doc).each { |err| p err.to_s }
        false
      end

      def validate_against_dtd(_xml_file, _dtd_file)
        # The DTD file for the PubMed Linkout file doesn't appear to be valid. The Nokogiri validation
        # fails with the following errors (whether checking against the remote DTD file or a local
        # downloaded copy of it):
        #    3:0: ERROR: No declaration for element LinkSet"
        #    4:0: ERROR: No declaration for element Link"
        #    5:0: ERROR: No declaration for element LinkId"
        #    6:0: ERROR: No declaration for element ProviderId"
        #    7:0: ERROR: No declaration for element IconUrl"
        #    8:0: ERROR: No declaration for element ObjectSelector"
        #    9:0: ERROR: No declaration for element Database"
        #    10:0: ERROR: No declaration for element ObjectList"
        #    11:0: ERROR: No declaration for element ObjId"
        #    12:0: ERROR: No declaration for element ObjId"
        #    13:0: ERROR: No declaration for element ObjId"
        #    16:0: ERROR: No declaration for element ObjectUrl"
        #    17:0: ERROR: No declaration for element Base"
        #    18:0: ERROR: No declaration for element Rule"
        #    19:0: ERROR: No declaration for element SubjectType"
        doc = Nokogiri::XML::Document.parse(File.read(xml_file))
        dtd = Nokogiri::XML::DTD.new(doc.internal_subset.name, Nokogiri::XML::Document.parse(File.read(dtd_file)))
        return true if dtd.validate(doc).empty?

        p "      ERROR! #{xml_file} does not conform to the XML schema defined in: #{dtd_file}:"
        dtd.validate(doc).each { |err| p "        #{err}" }
        false
      end

    end

  end
end
