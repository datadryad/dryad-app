FactoryBot.define do

  factory :curation_activity, class: StashEngine::CurationActivity do
    user
    resource

    status { 'in_progress' }
    note { Faker::Lorem.sentence }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :submitted do
      status { 'submitted' }
    end

    trait :peer_review do
      status { 'perr_review' }
    end

    trait :curation do
      status { 'curation' }
    end

    trait :acvtion_required do
      status { 'acvtion_required' }
    end

    trait :withdrawn do
      status { 'withdrawn' }
    end

    trait :embargoed do
      status { 'embargoed' }
    end

    trait :published do
      status { 'published' }
    end

    after(:create) do |curation_activity, evaluator|
      curation_activity.resource.update(latest_curation_activity_id: curation_activity.id)
    end

  end

end
