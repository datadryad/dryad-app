module StashEngine
  class FunderRole < ApplicationRecord
    self.table_name = 'stash_engine_funder_roles'
    belongs_to :user

    scope :admins, -> { where(role: 'admin') }
  end
end
