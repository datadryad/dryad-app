require 'digest'
require 'http'
require 'fileutils'

module Stash
  module ZenodoSoftware
    class File

      # MD2 is obsolete and doesn't seem to have a good implementation in Ruby
      # CRC-32 and adler-32 are checksums that don't think we're really using.
      DIGESTS = {
          'md5' => -> (file){ Digest::MD5.file(file).hexdigest },
          'sha-1' => -> (file){ Digest::SHA1.file(file).hexdigest },
          'sha-256' => -> (file){ Digest::SHA256.file(file).hexdigest },
          'sha-384' => -> (file){ Digest::SHA384.file(file).hexdigest },
          'sha-512' => -> (file){ Digest::SHA512.file(file).hexdigest }
      }
      # this take an ActiveRecord StashEngine::SoftwareUpload object
      def initialize(file_obj:)
        @file_obj = file_obj
        updir = file_obj.resource.software_upload_dir
        FileUtils.mkdir_p(updir) unless ::File.exist?(updir)
      end

      def check_file_exists
        return if ::File.exist?(@file_obj.calc_file_path)
        raise Stash::ZenodoSoftware::FileError, "Uploaded file doesn't exist: resource_id: #{@file_obj.resource_id}, " \
          "file_id: #{@file_obj.id}, name: #{@file_obj.upload_file_name}"
      end

      def check_digest
        return unless DIGESTS.keys.include?(@file_obj.digest_type)
        my_digest = DIGESTS[@file_obj.digest_type].call(@file_obj.calc_file_path)
        return if  my_digest == @file_obj.digest
        raise Stash::ZenodoSoftware::FileError, "Digest mismatch for file: resource_id: #{@file_obj.resource_id}, " \
          "file_id: #{@file_obj.id}, name: #{@file_obj.upload_file_name}\n" \
          "Type: #{@file_obj.digest_type}\n" \
          "Expected: #{@file_obj.digest_type}, got #{my_digest}"
      end

      def download
        resp = HTTP.timeout(connect: 30, read: 120).timeout(6.hours.to_i).follow(max_hops: 10).get(@file_obj.url)

        unless resp.status.success?
          raise Stash::ZenodoSoftware::FileError, "Bad download with http status: #{resp.status.code} -- resource_id: " \
            "#{@file_obj.resource_id}, file_id: #{@file_obj.id}, name: #{@file_obj.upload_file_name}, url: #{@file_obj.url}"
        end

        ::File.open(@file_obj.calc_file_path, 'wb') do |f|
          resp.body.each do |chunk|
            f.write(chunk)
          end
        end
      rescue HTTP::Error => ex
        raise Stash::ZenodoSoftware::FileError, "Received HTTP error while downloading\n" \
          "resource_id: #{@file_obj.resource_id}, file_id: #{@file_obj.id}, name: #{@file_obj.upload_file_name}, url: #{@file_obj.url}" \
          "Original Exception:\n#{ex}\n#{ex.backtrace.join("\n")}"
      end
    end
  end
end
