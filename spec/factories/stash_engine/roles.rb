FactoryBot.define do

  factory :role, class: StashEngine::Role do

    user
    role { 'admin' }
    association :role_object, factory: :tenant

  end

end
