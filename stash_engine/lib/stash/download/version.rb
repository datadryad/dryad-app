require_relative 'base'

module Stash
  module Download
    class Version < Base

      # this gets an answer from Merritt about whether this is an async download
      def merritt_async_download?(resource:)
        domain, local_id = resource.merritt_protodomain_and_local_id
        url = "#{domain}/async/#{local_id}/#{resource.stash_version.merritt_version}"

        res = Stash::Repo::HttpClient.new(tenant: resource.tenant, cert_file: APP_CONFIG.ssl_cert_file).client.get(url, follow_redirect: true)
        status = res.status_code

        return true if status == 200 # async download OK
        return false if status == 406 # 406 Not Acceptable means only synchronous download allowed

        # raise_merritt_error('Merritt async download check', "unexpected status #{status}", resource.id, url)
      end

    end
  end
end