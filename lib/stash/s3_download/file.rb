# I have been favoring the 'httprb/http' gem recently since it is small, fast and pretty easy to use, similar to Python's
# requests library. See https://twin.github.io/httprb-is-great/ .
require 'http'
require 'byebug'
require 'digest'
require 'fileutils'
require 'stash/download'

module Stash
  module S3Download # was MerrittDownload

    # calling this class File means we need to namespace the built-in Ruby file class when calling it in here
    class File

      attr_reader :path

      def initialize(resource:, path:)
        @resource = resource
        @path = path
        FileUtils.mkdir_p(@path) unless ::File.directory?(@path)
      end

      # download file a and return a hash, we should be tracking success routinely since downloads are error-prone
      def download_file(db_file:)
        s3_resp = get_url(url: db_file.s3_permanent_presigned_url)

        unless s3_resp.status.success?
          return { success: false,
                   error: "#{s3_resp.status.code} status code retrieving '#{db_file.upload_file_name}' " \
                          "for resource #{@resource.id}" }
        end

        md5 = Digest::MD5.new
        sha256 = Digest::SHA256.new

        # this doesn't load everything into memory at once and writes in chunks and calculates digests at the same time
        ::File.open(::File.join(@path, db_file.upload_file_name), 'wb') do |f|
          s3_resp.body.each do |chunk|
            f.write(chunk)
            md5.update(chunk)
            sha256.update(chunk)
          end
        end

        get_digests(md5_obj: md5, sha256_obj: sha256, db_file: db_file).merge(success: true)
      rescue HTTP::Error => e
        { success: false, error: "Error downloading file for resource #{@resource.id}\nHTTP::Error #{e}" }
      rescue Stash::Download::S3CustomError => e
        { success: false, error: "Error downloading file for resource #{@resource.id}\nS3CustomError: #{e}" }
      end

      # gets the file url and returns an HTTP.get(url) response object
      def get_url(url:, read_timeout: 30)
        http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
          .timeout(connect: 30, read: read_timeout).timeout(6.hours.to_i).follow(max_hops: 10)
        http.get(url)
      end

      def get_digests(md5_obj:, sha256_obj:, db_file:)
        md5_hex = md5_obj.hexdigest
        sha256_hex = sha256_obj.hexdigest

        return { md5_hex: md5_hex, sha256_hex: sha256_hex } if db_file.blank? || db_file.digest.blank?

        if (db_file.digest_type == 'md5' && db_file.digest != md5_hex) ||
            (db_file.digest_type == 'sha-256' && db_file.digest != sha_256_hex)
          raise Stash::S3Download::DownloadError, "Digest for downloaded file doesn't match database value. File.id: #{db_file.id}"
        end

        { md5_hex: md5_hex, sha256_hex: sha256_hex }
      end

    end
  end
end
