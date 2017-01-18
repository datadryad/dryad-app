require 'stash/repo'
require 'stash_ezid/client'

module Stash
  module Merritt
    module Ezid
      class UpdateMetadataTask < Stash::Repo::Task
        attr_reader :resource_id
        attr_reader :url_helpers
        attr_reader :tenant

        def initialize(resource_id:, tenant:, url_helpers:)
          @resource_id = resource_id
          @tenant = tenant
          @url_helpers = url_helpers
        end

        def landing_page_url
          @landing_page_url ||= url_helpers.show_path(identifier_str)
        end

        def identifier_str
          @identifier_str = begin
            resource = StashEngine::Resource.find(resource_id)
            resource.identifier_str
          end
        end

        # @param package [SubmissionPackage] the package to submit
        # @return [SubmissionPackage] the package
        def exec(package)
          ezid_client.update_metadata(identifier_str, package.dc3_xml, landing_page_url)
          package
        end

        def to_s
          "#{super}: resource #{resource_id} (#{identifier_str}), tenant #{tenant.tenant_id}, landing page #{landing_page_url}"
        end

        private

        def ezid_client
          @ezid_client ||= begin
            id_params = tenant.identifier_service
            StashEzid::Client.new(
              shoulder: id_params.shoulder,
              account: id_params.account,
              password: id_params.password,
              owner: id_params.owner,
              id_scheme: id_params.scheme
            )
          end
        end
      end
    end
  end
end
