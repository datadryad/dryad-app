FactoryBot.define do

  factory :role, class: StashEngine::Role do
    transient { role_object { nil } }

    user
    role { 'admin' }
    role_object_type { role_object&.class&.name || nil }
    role_object_id { role_object&.id || nil }

  end
end
