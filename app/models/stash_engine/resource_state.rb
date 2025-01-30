# == Schema Information
#
# Table name: stash_engine_resource_states
#
#  id             :integer          not null, primary key
#  resource_state :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  resource_id    :integer
#  user_id        :integer
#
# Indexes
#
#  index_stash_engine_resource_states_on_resource_id     (resource_id)
#  index_stash_engine_resource_states_on_resource_state  (resource_state)
#  index_stash_engine_resource_states_on_user_id         (user_id)
#
module StashEngine
  class ResourceState < ApplicationRecord
    self.table_name = 'stash_engine_resource_states'
    belongs_to :user
    belongs_to :resource

    enum(:resource_state, %w[in_progress processing submitted error].to_h { |i| [i.to_sym, i] })

    validates :resource_state, presence: true
  end
end
