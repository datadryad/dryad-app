# rubocop:disable Metrics/BlockLength
FactoryBot.define do

  factory :resource, class: StashEngine::Resource do
    identifier
    user

    has_geolocation { false }
    title { Faker::Lorem.sentence }
    download_uri { Faker::Internet.url }
    update_uri { Faker::Internet.url }

    before(:create) do |resource|
      resource.tenant_id = resource.user.present? ? resource.user.tenant_id : 'dryad'
    end

    after(:create) do |resource|
      create(:author, resource: resource)
      create(:description, resource_id: resource.id)
    end

    trait :submitted do
      after(:create) do |resource|
        resource.share = build(:share, resource_id: resource.id, tenant: resource.tenant_id)
        resource.current_resource_state_id = create(:resource_state, :submitted, user: resource.user, resource: resource).id
        resource.save
        resource.reload
      end
    end

  end

  # Create a resource that has reached the embargoed curation status
  factory :resource_embargoed, parent: :resource, class: StashEngine::Resource do

    publication_date { (Date.today + 2.days).to_s }
    submitted

    after(:create) do |resource|
      create(:curation_activity, :curation, user: resource.user, resource: resource)
      current_curation_activity_id do
        create(:curation_activity, :embargoed, resource: resource,
                                               user: create(:user, role: 'admin',
                                                                   tenant_id: resource.user.tenant_id)).id
      end
    end

  end

  # Create a resource that has reached the published curation status
  factory :resource_published, parent: :resource, class: StashEngine::Resource do

    publication_date { Date.today.to_s }
    submitted

    after(:create) do |resource|
      create(:curation_activity, :curation, user: resource.user, resource: resource)
      current_curation_activity_id do
        create(:curation_activity, :published, resource: resource,
                                               user: create(:user, role: 'admin',
                                                                   tenant_id: resource.user.tenant_id)).id
      end
    end

  end

end
# rubocop:enable Metrics/BlockLength
