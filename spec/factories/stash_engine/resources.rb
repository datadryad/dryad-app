# == Schema Information
#
# Table name: stash_engine_resources
#
#  id                        :integer          not null, primary key
#  accepted_agreement        :boolean
#  cedar_json                :text(65535)
#  display_readme            :boolean          default(TRUE)
#  download_uri              :text(65535)
#  file_view                 :boolean          default(FALSE)
#  has_geolocation           :boolean          default(FALSE)
#  hold_for_peer_review      :boolean          default(FALSE)
#  loosen_validation         :boolean          default(FALSE)
#  meta_view                 :boolean          default(FALSE)
#  peer_review_end_date      :datetime
#  preserve_curation_status  :boolean          default(FALSE)
#  publication_date          :datetime
#  skip_datacite_update      :boolean          default(FALSE)
#  skip_emails               :boolean          default(FALSE)
#  solr_indexed              :boolean          default(FALSE)
#  title                     :text(65535)
#  total_file_size           :bigint
#  update_uri                :text(65535)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  current_editor_id         :integer
#  current_resource_state_id :integer
#  identifier_id             :integer
#  last_curation_activity_id :integer
#  old_resource_id           :integer
#  tenant_id                 :string(100)
#  user_id                   :integer
#
# Indexes
#
#  index_stash_engine_resources_on_current_editor_id             (current_editor_id)
#  index_stash_engine_resources_on_identifier_id                 (identifier_id)
#  index_stash_engine_resources_on_identifier_id_and_created_at  (identifier_id,created_at) UNIQUE
#  index_stash_engine_resources_on_tenant_id                     (tenant_id)
#  index_stash_engine_resources_on_user_id                       (user_id)
#
FactoryBot.define do

  factory :resource, class: StashEngine::Resource do
    transient { user { nil } }
    identifier

    has_geolocation { true }
    title { Faker::Lorem.sentence }
    download_uri { "http://storage-fake.datadryad.org/d/ark%3A%2F99999%2Ffk#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
    update_uri do
      "http://storage-fake.org:39001/mrtsword/edit/#{Faker::Alphanumeric.alpha(number: 8)}/" \
        "doi%3A10.5061%2Fdryad.#{Faker::Alphanumeric.alphanumeric(number: 6)}"
    end
    publication_date { Time.new.utc }

    before(:create) do |resource, e|
      user = e.user || StashEngine::User.find_by(id: resource.user_id) || create(:user)
      resource.tenant_id = user.tenant_id
      resource.current_editor_id = user.id unless resource.current_editor_id
    end

    after(:create) do |resource, e|
      unless resource.creator
        user = e.user || create(:user)
        create(:role, user_id: resource.user_id || user.id, role_object: resource, role: 'creator')
        create(:role, user_id: resource.user_id || user.id, role_object: resource, role: 'submitter')
        resource.update_columns(user_id: nil)
      end
      create(:author, resource: resource)
      create(:description, resource_id: resource.id)
      create(:right, resource: resource)
      create(:contributor, resource: resource)
      resource.subjects << create(:subject, subject: Faker::Lorem.unique.word, subject_scheme: 'fos')
      3.times { resource.subjects << create(:subject, subject: Faker::Lorem.unique.word) }
    end

    trait :submitted do
      after(:create) do |resource|
        create(:curation_activity, status: 'processing', user: resource.submitter, resource: resource)
        resource.current_state = 'submitted'
        resource.save
        resource.reload
      end
    end

  end

  # Create a resource that has reached the embargoed curation status
  factory :resource_embargoed, parent: :resource, class: StashEngine::Resource do

    publication_date { (Time.now.utc.to_date + 2.days).to_s }
    submitted

    after(:create) do |resource|
      create(:curation_activity, :curation, user: resource.submitter, resource: resource)
      create(:curation_activity,
             :embargoed, resource: resource,
                         user: create(:user, role: 'admin', role_object: resource.submitter.tenant, tenant_id: resource.submitter.tenant_id)).id
    end

  end

  # Create a resource that has reached the published curation status
  factory :resource_published, parent: :resource, class: StashEngine::Resource do

    publication_date { Time.now.utc.to_date.to_s }
    submitted

    after(:create) do |resource|
      create(:curation_activity, :curation, user: resource.submitter, resource: resource)
      create(:curation_activity,
             :published, resource: resource,
                         user: create(:user, role: 'admin', role_object: resource.submitter.tenant, tenant_id: resource.submitter.tenant_id)).id
    end

  end

end
