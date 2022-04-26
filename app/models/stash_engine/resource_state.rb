module StashEngine
  class ResourceState < ApplicationRecord
    self.table_name = 'stash_engine_resource_states'
    belongs_to :user
    belongs_to :resource

    enum resource_state: %w[in_progress processing submitted error].map { |i| [i.to_sym, i] }.to_h
    validates :resource_state, presence: true
  end
end
