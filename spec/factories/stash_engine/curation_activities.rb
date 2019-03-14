# rubocop:disable Metrics/BlockLength
FactoryBot.define do

  factory :curation_activity, class: StashEngine::CurationActivity do
    resource

    user { create(:user) }
    status { 'in_progress' }
    note { Faker::Lorem.sentence }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :submitted do
      status { 'submitted' }
    end

    trait :peer_review do
      status { 'peer_review' }
    end

    trait :curation do
      status { 'curation' }
    end

    trait :action_required do
      status { 'action_required' }
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

  end

end
# rubocop:enable Metrics/BlockLength
