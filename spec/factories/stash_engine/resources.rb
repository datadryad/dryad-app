FactoryBot.define do

  factory :resource, class: StashEngine::Resource do
    identifier

    has_geolocation { false }
    title { Faker::Lorem.sentence }
    download_uri { Faker::Internet.url }
    update_uri { Faker::Internet.url }

    before(:create) do |resource, evaluator|
      resource.tenant_id = resource.user&.tenant_id || 'dryad'
    end

    after(:create) do |resource, evaluator|
      if resource.resource_states.empty?
        create(:resource_state, :in_progress, user: resource.user, resource: resource)
      end
      resource.identifier.latest_resource_id = resource.id
    end

    transient do
      resource_states { 0 }
      curation_activities { 0 }
      editor { 0 }
      user { 0 }
    end

    trait :submitted do
      after(:create) do |resource, evaluator|
        create(:resource_state, :submitted, user: resource.user, resource: resource)
        current_curation_activity_id = create(:curation_activity, :submitted, user: resource.user, resource: resource).id
      end
    end

    trait :embargoed do
      publication_date = (Date.today + 2.days).to_s
      after(:create) do |resource, evaluator|
        create(:resource_state, :submitted, user: resource.user, resource: resource)
        create(:curation_activity, :submitted, user: resource.user, resource: resource)
        create(:curation_activity, :curation, user: resource.user, resource: resource)
        current_curation_activity_id = create(:curation_activity, :embargoed, user: resource.user, resource: resource).id
      end
    end

    trait :published do
      publication_date = Date.today.to_s
      after(:create) do |resource, evaluator|
        create(:resource_state, :submitted, user: resource.user, resource: resource)
        create(:curation_activity, :submitted, user: resource.user, resource: resource)
        create(:curation_activity, :curation, user: resource.user, resource: resource)
        current_curation_activity_id = create(:curation_activity, :published, user: resource.user, resource: resource).id
      end
    end

  end

end
