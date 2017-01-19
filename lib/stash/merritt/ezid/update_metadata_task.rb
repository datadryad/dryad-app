require 'stash/repo'
require 'stash_ezid/client'

module Stash
  module Merritt
    module Ezid
      class UpdateMetadataTask < Stash::Repo::Task
        attr_reader :url_helpers

        def initialize(url_helpers:)
          @url_helpers = url_helpers
        end

        # @param package [SubmissionPackage] the package to submit
        # @return [SubmissionPackage] the package
        def exec(package)
          resource = package.resource
          identifier_str = resource.identifier_str
          landing_page_url = url_helpers.show_path(identifier_str)
          ezid_client = ezid_client_for(resource.tenant)
          ezid_client.update_metadata(identifier_str, package.dc3_xml, landing_page_url)
          package
        end

        private

        def ezid_client_for(tenant)
          id_params = tenant.identifier_service
          StashEzid::Client.new(
            shoulder:  id_params.shoulder,
            account:   id_params.account,
            password:  id_params.password,
            owner:     id_params.owner,
            id_scheme: id_params.scheme
          )
        end
      end
    end
  end
end
