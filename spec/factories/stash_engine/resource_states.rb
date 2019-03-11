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
