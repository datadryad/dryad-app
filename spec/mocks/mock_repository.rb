require 'stash/repo'

module Stash
  # configured in stash_engine_specs/config/app_config.yml
  class MockRepository < Stash::Repo::Repository
  end
end
