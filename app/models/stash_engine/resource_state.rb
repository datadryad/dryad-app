module StashEngine
  class ResourceState < ApplicationRecord
    self.table_name = 'stash_engine_resource_states'
    belongs_to :user
    belongs_to :resource

    enum resource_state: %w[in_progress processing submitted error].to_h { |i| [i.to_sym, i] }
    validates :resource_state, presence: true
  end
end
