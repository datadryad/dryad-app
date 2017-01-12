require 'stash/repo'
require 'stash_ezid/client'

module Stash
  module Merritt
    module Ezid
      class EnsureIdentifierTask < Stash::Repo::Task
        attr_reader :ezid_client
        attr_reader :resource_id

        # @param ezid_client [StashEzid::Client] the EZID client
        def initialize(resource_id:, ezid_client:)
          @ezid_client = ezid_client
          @resource_id = resource_id
        end

        # @return [String] the identifier (DOI, ARK, or URN)
        def exec(*)
          resource = Resource.find(resource_id)
          identifier_str = resource.identifier_str
          return identifier_str if identifier_str

          new_identifier_str = ezid_client.mint_id
          resource.ensure_identifier(new_identifier_str)
          new_identifier_str
        end
      end
    end
  end
end
