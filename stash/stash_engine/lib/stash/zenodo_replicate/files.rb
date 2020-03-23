require 'http'
require 'stash/zenodo_replicate/zenodo_connection'

module Stash
  module ZenodoReplicate
    class Files

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      attr_reader :resource, :file_collection

      def initialize(resource:, file_collection:)
        @resource = resource
        @file_collection = file_collection

        # the file_collection has .path and .info_hash properties
        # the info hash of Merritt files is like key=filename, value = { success: <t/f>, sha256_digest:, md5_digest: }

        @resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{@resource.zenodo_third_copy.deposition_id}")

        # just gets filenames for items already in Zenodo
        @existing_zenodo_filenames = @resp[:files].map { |f| f[:filename] }

        @existing_dryad_filenames = @file_collection.info_hash.keys

        @zenodo_fn_hash = {}
        @resp[:files].each do |f|
          @zenodo_fn_hash[f[:filename]] = f
        end
      end

      def replicate
        remove_files
        upload_files
      end

      def upload_files
        @existing_dryad_filenames.each do |fn|
          # upload if file doesn't exist in Zenodo or the previous digest doesn't match the new digest
          upload_file(filename: fn) if @zenodo_fn_hash[fn].nil? || @zenodo_fn_hash[fn][:checksum] != @file_collection.info_hash[fn][:md5_hex]
        end
      end

      def upload_file(filename:)
        upload_file = File.join(@file_collection.path.to_s, filename)
        upload_url = "#{@resp[:links][:bucket]}/#{ERB::Util.url_encode(filename)}"

        # remove the json content type since this is binary
        resp = ZC.standard_request(:put, upload_url, body: File.open(upload_file, 'rb'), headers: { 'Content-Type': nil })

        unless resp[:checksum] == "md5:#{@file_collection.info_hash[filename][:md5_hex]}"
          raise ZenodoError, "Mismatched digests for #{upload_url}\n#{resp[:checksum]} vs #{@file_collection.info_hash[filename][:md5_hex]}"
        end
        resp
      end

      def remove_files
        removed_filenames.each do |fn|
          ZC.standard_request(:delete, @zenodo_fn_hash[fn][:links][:download])
        end
      end

      def removed_filenames
        @zenodo_fn_hash.keys - @existing_dryad_filenames
      end
    end
  end
end
