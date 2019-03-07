require 'stash/repo'

module Stash
  # configured in stash_engine_specs/config/app_config.yml
  class MockRepository < Stash::Repo::Repository

    def mint_id(*)
      'doi:12345/67890'
    end
  end
end
