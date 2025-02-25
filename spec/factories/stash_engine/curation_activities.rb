# == Schema Information
#
# Table name: stash_engine_curation_activities
#
#  id          :integer          not null, primary key
#  deleted_at  :datetime
#  keywords    :string(191)
#  note        :text(65535)
#  status      :string(191)      default("in_progress")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#  user_id     :integer
#
# Indexes
#
#  index_stash_engine_curation_activities_on_deleted_at          (deleted_at)
#  index_stash_engine_curation_activities_on_resource_id_and_id  (resource_id,id)
#
FactoryBot.define do

  factory :curation_activity, class: StashEngine::CurationActivity do
    resource

    user { create(:user) }
    status { 'in_progress' }
    note { Faker::Lorem.sentence }
    deleted_at { nil }

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
        ca.define_singleton_method(:submit_to_datacite) {} # empty to remove callback
        ca.define_singleton_method(:update_solr) {} # empty to remove callback
        ca.define_singleton_method(:process_payment) {} # empty to remove callback
        ca.define_singleton_method(:email_status_change_notices) {} # empty to remove callback
        ca.define_singleton_method(:email_orcid_invitations) {} # empty to remove callback
      end
    end
  end
end
