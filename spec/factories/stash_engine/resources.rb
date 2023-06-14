FactoryBot.define do

  factory :resource, class: StashEngine::Resource do
    identifier
    user

    has_geolocation { true }
    title { Faker::Lorem.sentence }
    download_uri { "http://merritt-fake.cdlib.org/d/ark%3A%2F99999%2Ffk#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
    update_uri do
      "http://mrtsword-fake.cdlib.org:39001/mrtsword/edit/#{Faker::Alphanumeric.alpha(number: 8)}/" \
        "doi%3A10.5061%2Fdryad.#{Faker::Alphanumeric.alphanumeric(number: 6)}"
    end
    publication_date { Time.new.utc }

    before(:create) do |resource|
      resource.tenant_id = resource.user.present? ? resource.user.tenant_id : 'dryad'
    end

    after(:create) do |resource|
      create(:author, resource: resource)
      create(:description, resource_id: resource.id)
      create(:right, resource: resource)
      create(:contributor, resource: resource)
      resource.subjects << create(:subject, subject_scheme: 'fos')
      3.times { resource.subjects << create(:subject) }
    end

    trait :submitted do
      after(:create) do |resource|
        resource.current_state = 'submitted'
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
      create(:curation_activity, :embargoed, resource: resource,
                                             user: create(:user, role: 'admin',
                                                                 tenant_id: resource.user.tenant_id)).id
    end

  end

  # Create a resource that has reached the published curation status
  factory :resource_published, parent: :resource, class: StashEngine::Resource do

    publication_date { Date.today.to_s }
    submitted

    after(:create) do |resource|
      create(:curation_activity, :curation, user: resource.user, resource: resource)
      create(:curation_activity, :published, resource: resource,
                                             user: create(:user, role: 'admin',
                                                                 tenant_id: resource.user.tenant_id)).id
    end

  end

end
