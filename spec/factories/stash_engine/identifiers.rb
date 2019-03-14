FactoryBot.define do

  factory :identifier, class: StashEngine::Identifier do

    identifier { Faker::Pid.doi }
    identifier_type { 'DOI' }
    storage_size { Faker::Number.number(5) }
    license_id { 'cc0' }

    transient do
      resources { 0 }
    end

    # Make sure the latest_resource_id is updated
    after(:create) do |identifier|
      identifier.latest_resource_id { identifier.resources.last.id } unless identifier.resources.empty?
    end

  end

end
