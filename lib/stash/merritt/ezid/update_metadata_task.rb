require 'stash/repo'
require 'stash_ezid/client'

module Stash
  module Merritt
    module Ezid
      class UpdateMetadataTask < Stash::Repo::Task

        attr_reader :ezid_client
        attr_reader :resource_id
        attr_reader :url_helpers

        def initialize(ezid_client:, url_helpers:, resource_id:)
          @url_helpers = url_helpers
          @resource_id = resource_id
          @ezid_client = ezid_client
        end

        def landing_page_url
          @landing_page_url ||= url_helpers.show_path(identifier_str)
        end

        def identifier_str
          @identifier_str = begin
            resource = Resource.find(resource_id)
            resource.identifier_str
          end
        end

        # @param package [SubmissionPackage] the package to submit
        # @return [SubmissionPackage] the package
        def exec(package)
          datacite_xml_str = package.datacite_xml_str
          ezid_client.update_metadata(identifier_str, datacite_xml_str, landing_page_url)
          package
        end

        def to_s
          "#{super}: updating metadata for resource #{resource_id} (#{identifier_str}) with landing page #{landing_page_url}"
        end
      end
    end
  end
end
