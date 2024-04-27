module StashEngine
  class Funder < ApplicationRecord
    self.table_name = 'stash_engine_funders'
    belongs_to :ror_org, class_name: 'StashEngine::RorOrg', primary_key: 'ror_id', foreign_key: 'ror_id', optional: true
    has_many :roles, class_name: 'StashEngine::Role', as: :role_object
    has_many :users, through: :roles

    enum payment_plan: {
      tiered: 0
    }

    scope :exemptions, -> { where(enabled: true, covers_dpc: true) }
  end
end
