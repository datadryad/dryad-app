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

    factory(:curation_activity_no_callbacks) do
      before(:create) do |ca|
        # redefine these  methods so I can set this crap in peace without all the horror
        # https://stackoverflow.com/questions/8751175/skip-callbacks-on-factory-girl-and-rspec
        ca.define_singleton_method(:submit_to_datacite) {}
        ca.define_singleton_method(:update_solr) {}
        ca.define_singleton_method(:submit_to_stripe) {}
        ca.define_singleton_method(:email_author) {}
        ca.define_singleton_method(:email_orcid_invitations) {}
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
