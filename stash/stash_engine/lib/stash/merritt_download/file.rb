# this is really for an individual file download from Merritt to a file and is not a user file-download and streaming class

# notes on development test data
# https://dryad-dev.cdlib.org/stash/dataset/doi:10.5061/dryad.n10d7
# identifier_id: 761
# resource_id: 785
# file names: 'Madagascarophis Nexus Files.zip', 'Madagascarophis_trees.zip', 'mrt-datacite.xml', 'mrt-oaidc.xml', 'stash-wrapper.xml'
#
# require 'stash/merritt_download'
# resource = StashEngine::Resource.find(785)
# smdf = Stash::MerrittDownload::File.new(resource: resource, filename: 'Madagascarophis Nexus Files.zip')
# smdf.download_file

# I have been favoring the 'httprb/http' gem recently since it is small, fast and pretty easy to use, similar to Python's
# requests library. See https://twin.github.io/httprb-is-great/ .
require 'http'
require 'tempfile'
require 'cgi'
require 'fileutils'
require 'byebug'

module Stash
  module MerrittDownload
    # calling this class File means we need to namespace the built-in Ruby file class when calling it in here
    class File

      # we need to be able to download any file from Merritt, including a couple of hidden ones we don't track as user-files (mrt-datacite.xml)
      # so we will need some individual information such as resource and filename and can't use database file_id since it doesn't exist for some
      def initialize(resource:, filename:)
        @resource = resource
        @filename = filename

        # the 'upload' path is a symlinked shared EFS mount on servers
        @path = Rails.root.join('uploads', 'zenodo_replication', resource.id.to_s)
        FileUtils.mkdir_p(@path) # makes entire path to this file if is needed
      end

      # download file a and return a hash, we should be tracking success routinely since downloads are error-prone
      def download_file
        mrt_resp = get_url

        unless mrt_resp.status.success?
          return { success: false, error: "#{mrt_resp.status.code} status code retrieving '#{@filename}' for resource #{@resource.id}" }
        end

        # this doesn't load everything into memory at once and writes in chunks, which is good for not blowing out memory by slurping
        ::File.open(::File.join(@path, @filename), 'wb') do |f|
          mrt_resp.body.each do |chunk|
            f.write(chunk)
          end
        end

        { success: true }
      rescue HTTP::Error => ex
        { success: false, error: "Error retrieving '#{@filename}' for resource #{@resource.id}\n#{ex}" }
      end

      # gets the file url and returns an HTTP.get(url) response object
      def get_url(read_timeout: 30)
        url = download_file_url

        http = HTTP.timeout(connect: 30, read: read_timeout).timeout(7200).follow(max_hops: 10)
          .basic_auth(user: @resource.tenant.repository.username, pass: @resource.tenant.repository.password)

        http.get(url)
      end

      def download_file_url
        # domain is not used for MerrittExpress, because the domain is different than the one given by SWORD, only for Merritt UI
        _domain, ark = @resource.merritt_protodomain_and_local_id

        "#{APP_CONFIG.merritt_express_base_url}/dv/#{@resource.stash_version.merritt_version}" \
          "/#{CGI.unescape(ark)}/#{ERB::Util.url_encode(@filename).gsub('%252F', '%2F')}"
      end

    end
  end
end
