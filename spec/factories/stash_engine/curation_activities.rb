# == Schema Information
#
# Table name: stash_engine_curation_activities
#
#  id            :integer          not null, primary key
#  deleted_at    :datetime
#  keywords      :string(191)
#  note          :text(65535)
#  status        :string(191)      default("in_progress")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#  resource_id   :integer
#  user_id       :integer
#
# Indexes
#
#  index_stash_engine_curation_activities_on_deleted_at          (deleted_at)
#  index_stash_engine_curation_activities_on_identifier_id       (identifier_id)
#  index_stash_engine_curation_activities_on_resource_id_and_id  (resource_id,id)
#
FactoryBot.define do

  factory :curation_activity, class: StashEngine::CurationActivity do
    resource

    user { create(:user) }
    status { 'in_progress' }
    note { Faker::Lorem.sentence }
    deleted_at { nil }
    identifier_id { resource.identifier_id }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :queued do
      status { 'queued' }
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

    trait :awaiting_payment do
      status { 'awaiting_payment' }
    end

    trait :withdrawn do
      status { 'withdrawn' }
      after(:create) do |act|
        act.resource.update(meta_view: false, file_view: false)
        act.resource.identifier.update(pub_state: 'withdrawn')
      end
    end

    trait :retracted do
      status { 'retracted' }
      after(:create) do |act|
        act.resource.update(meta_view: true)
        act.resource.identifier.update(pub_state: 'retracted')
      end
    end

    trait :embargoed do
      status { 'embargoed' }
      after(:create) do |act|
        act.resource.update(meta_view: true, file_view: false)
        act.resource.identifier.update(pub_state: 'embargoed')
      end
    end

    trait :published do
      status { 'published' }
      after(:create) do |act|
        act.resource.update(meta_view: true, file_view: act.resource.files_changed?)
        act.resource.identifier.update(pub_state: 'published')
      end
    end
  end
end
