# == Schema Information
#
# Table name: stash_engine_identifiers
#
#  id                      :integer          not null, primary key
#  deleted_at              :datetime
#  downloaded_at           :datetime
#  edit_code               :string(191)
#  identifier              :text(65535)
#  identifier_type         :text(65535)
#  import_info             :integer
#  issues                  :json
#  last_invoiced_file_size :bigint
#  old_payment_system      :boolean          default(FALSE)
#  payment_type            :string(191)
#  pub_state               :string
#  publication_date        :datetime
#  search_words            :text(65535)
#  storage_size            :bigint
#  waiver_basis            :string(191)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  latest_resource_id      :integer
#  license_id              :string(191)
#  payment_id              :text(65535)
#  software_license_id     :integer
#
# Indexes
#
#  admin_search_index                                     (search_words)
#  index_stash_engine_identifiers_on_deleted_at           (deleted_at)
#  index_stash_engine_identifiers_on_identifier           (identifier)
#  index_stash_engine_identifiers_on_latest_resource_id   (latest_resource_id)
#  index_stash_engine_identifiers_on_license_id           (license_id)
#  index_stash_engine_identifiers_on_software_license_id  (software_license_id)
#
FactoryBot.define do

  factory :identifier, class: StashEngine::Identifier do

    identifier { Faker::Pid.doi }
    identifier_type { 'DOI' }
    storage_size { Faker::Number.number(digits: 5) }
    license_id { 'cc0' }
    deleted_at { nil }

    transient do
      resources { 0 }
    end

    # Make sure the latest_resource_id is updated
    after(:create) do |identifier|
      identifier.shares = [build(:share, identifier_id: identifier.id)]
    end

  end

end
