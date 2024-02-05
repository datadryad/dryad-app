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
FactoryBot.define do

  factory :resource_state, class: StashEngine::ResourceState do
    user
    resource

    resource_state { 'in_progress' }

    trait :in_progress do
      resource_state { 'in_progress' }
    end

    trait :processing do
      resource_state { 'processing' }
    end

    trait :error do
      resource_state { 'error' }
    end

    trait :submitted do
      resource_state { 'submitted' }
    end

  end

end
