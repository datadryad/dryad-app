# this is really for an individual file download from Merritt to a file

# example file names: 'Madagascarophis Nexus Files.zip', 'Madagascarophis_trees.zip', 'mrt-datacite.xml', 'mrt-oaidc.xml', 'stash-wrapper.xml'
#
# example:
# require 'stash/merritt_download'
# resource = StashEngine::Resource.find(785)
# smdf = Stash::MerrittDownload::File.new(resource: resource)
# smdf.download_file(filename: 'Madagascarophis Nexus Files.zip')

# I have been favoring the 'httprb/http' gem recently since it is small, fast and pretty easy to use, similar to Python's
# requests library. See https://twin.github.io/httprb-is-great/ .
require 'http'
require 'tempfile'
require 'cgi'
require 'byebug'
require 'digest'

module Stash
  module MerrittDownload

    # calling this class File means we need to namespace the built-in Ruby file class when calling it in here
    class File

      attr_reader :path

      # we need to be able to download any file from Merritt, including a couple of hidden ones we don't track as user-files (mrt-datacite.xml)
      # so we will need some individual information such as resource and filename and can't use database file_id since it doesn't exist for some
      def initialize(resource:, path:)
        @resource = resource
        @path = path
      end

      # download file a and return a hash, we should be tracking success routinely since downloads are error-prone
      def download_file(db_file:)
        mrt_resp = get_url(filename: db_file.upload_file_name)

        unless mrt_resp.status.success?
          return { success: false, error: "#{mrt_resp.status.code} status code retrieving '#{db_file.upload_file_name}' for resource #{@resource.id}" }
        end

        md5 = Digest::MD5.new
        sha256 = Digest::SHA256.new

        # this doesn't load everything into memory at once and writes in chunks and calculates digests at the same time
        ::File.open(::File.join(@path, db_file.upload_file_name), 'wb') do |f|
          mrt_resp.body.each do |chunk|
            f.write(chunk)
            md5.update(chunk)
            sha256.update(chunk)
          end
        end

        get_digests(md5_obj: md5, sha256_obj: sha256, db_file: db_file).merge(success: true)
      rescue HTTP::Error => ex
        { success: false, error: "Error downloading file for resource #{@resource.id}\nHTTP::Error #{ex}" }
      end

      # gets the file url and returns an HTTP.get(url) response object
      def get_url(filename:, read_timeout: 30)
        url = download_file_url(filename: filename)

        http = HTTP.timeout(connect: 30, read: read_timeout).timeout(7200).follow(max_hops: 10)
          .basic_auth(user: @resource.tenant.repository.username, pass: @resource.tenant.repository.password)

        http.get(url)
      end

      def download_file_url(filename:)
        # domain is not used for MerrittExpress, because the domain is different than the one given by SWORD, only for Merritt UI
        _domain, ark = @resource.merritt_protodomain_and_local_id

        "#{APP_CONFIG.merritt_express_base_url}/dv/#{@resource.stash_version.merritt_version}" \
          "/#{CGI.unescape(ark)}/#{ERB::Util.url_encode(filename).gsub('%252F', '%2F')}"
      end

      def get_digests(md5_obj:, sha256_obj:, db_file:)
        md5_hex = md5_obj.hexdigest
        sha256_hex = sha256_obj.hexdigest

        if db_file && !db_file.digest.blank?
          if (db_file.digest_type == 'md5' && db_file.digest != md5_hex) ||
              (db_file.digest_type == 'sha-256' && db_file.digest != sha_256_hex)
            raise Stash::MerrittDownload::DownloadError, "Digest for downloaded file does match database value. File.id: #{db_file.id}"
          end
        end

        { md5_hex: md5_hex, sha256_hex: sha256_hex}
      end

    end
  end
end
