require_relative 'base'

module Stash
  module Download
    class Version < Base

      attr_accessor :resource

      # this gets an answer from Merritt about whether this is an async download
      def merritt_async_download?(resource:)
        @resource = resource
        domain, local_id = resource.merritt_protodomain_and_local_id
        url = "#{domain}/async/#{local_id}/#{resource.stash_version.merritt_version}"

        res = Stash::Repo::HttpClient.new(tenant: resource.tenant, cert_file: APP_CONFIG.ssl_cert_file).client.get(url, follow_redirect: true)
        status = res.status_code

        return true if status == 200 # async download OK
        return false if status == 406 # 406 Not Acceptable means only synchronous download allowed

        raise_merritt_error('Merritt async download check', "unexpected status #{status}", resource.id, url)
      end

      def self.merritt_friendly_async_url(resource:)
        domain, local_id = resource.merritt_protodomain_and_local_id
        "#{domain}/asyncd/#{local_id}/#{resource.stash_version.merritt_version}"
      end

      # this downloads a full version as a stream from Merritt UI and takes a block with a redirect for
      # the place to go for an asynchronous download from Merritt
      def download(resource:)
        @async_download = merritt_async_download?(resource: resource)
        if @async_download
          yield
        else
          StashEngine::CounterLogger.version_download_hit(request: cc.request, resource: resource)
          # longer read timeout since Merritt may need to assemble zip file before starting download
          stream_response(url: resource.merritt_producer_download_uri, tenant: resource.tenant, filename: disposition_filename, read_timeout: 180)
        end
      end

      # make it give a filename based on DOI and version with stuff sanitized out
      def disposition_filename
        fn = Zaru.sanitize!(@resource.identifier.to_s.gsub(%r{[\:\\/]+}, '_'))
        fn.gsub!(/,|;|'|"|\u007F/, '')
        fn << "__v#{@resource.stash_version.version}"
        "#{fn}.zip"
      end

      def raise_merritt_error(operation, details, resource_id, uri)
        raise Stash::Download::MerrittResponseError, "#{operation}: #{details} for resource ID #{resource_id}, URL #{uri}"
      end

    end
  end
end
