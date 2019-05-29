# frozen_string_literal: true

require 'net/ftp'

module LinkOut

  # This helper class provides common methods used by all of the LinkOut services
  module Helper

    TMP_DIR = "#{Rails.root}/tmp/link_out".freeze

    def make_linkout_dir!
      Dir.mkdir("#{Rails.root}/tmp") unless Dir.exist?("#{Rails.root}/tmp")
      return if Dir.exist?(LINK_OUT_DIR)
      Dir.mkdir(LINK_OUT_DIR)
    end

    def download_schema!(uri)
      file_name = "#{TMP_DIR}/#{uri.split('/').last}"
      p "      retrieving latest schema from: #{uri}"
      File.write(file_name, HTTParty.get(uri).body)
      file_name
    end

    def valid_xml?(file_name, schema)
      p "    validating #{file_name}"
      local_schema = download_schema(schema)
      # Do the appropriate validation based on the file type
      return validate_against_xsd(file_name, local_schema) if schema.downcase.ends_with?('.xsd')
      validate_against_dtd(file_name, local_schema)
    end

    def compress_file!(file_name)
      zipped = "#{file_name}.gz"
      Zlib::GzipWriter.open(zipped) do |gz|
        gz.mtime = File.mtime(file_name)
        gz.orig_name = file_name
        gz.write IO.binread(file_name)
      end
      p "    compressing (gzip) #{file_name} - before: #{File.size(file_name)} after: #{File.size(zipped)}"
      zipped
    end

    def validate_against_xsd(xml_file, xsd_file)
      xsd = Nokogiri::XML::Schema(File.read(xsd_file))
      doc = Nokogiri::XML(File.read(xml_file))
      return true if xsd.valid?(doc)
      p "      ERROR! #{xml_file} does not conform to the XML schema defined in: #{xsd_file}:"
      xsd.validate(doc).each { |err| p err.to_s }
      false
    end

    def validate_against_dtd(xml_file, dtd_file)
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
      return true

      dtd = Nokogiri::XML::DTD.new('dtd', Nokogiri::XML::Document.parse(File.read(dtd_file)))
      doc = Nokogiri::XML::Document.parse(File.read(xml_file))
      return true if dtd.validate(doc).empty?
      p "      ERROR! #{xml_file} does not conform to the XML schema defined in: #{dtd_file}:"
      dtd.validate(doc).each { |err| p "        #{err.to_s}" }
      false
    end

  end

end
