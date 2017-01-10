require 'stash/repo'
require 'stash_ezid/client'

module Stash
  module Merritt
    module Ezid
      class MintIdentifierTask < Stash::Repo::Task
        attr_reader :ezid_client

        # @param ezid_client [StashEzid::Client] the EZID client
        def initialize(ezid_client:)
          @ezid_client = ezid_client
        end

        # @return [String] the identifier (DOI, ARK, or URN)
        def exec
          ezid_client.mint_id
        end
      end
    end
  end
end
