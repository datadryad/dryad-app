# == Schema Information
#
# Table name: stash_engine_identifiers
#
#  id                  :integer          not null, primary key
#  identifier          :text(65535)
#  identifier_type     :text(65535)
#  storage_size        :bigint
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  latest_resource_id  :integer
#  license_id          :string(191)      default("cc0")
#  search_words        :text(65535)
#  payment_type        :string(191)
#  payment_id          :text(65535)
#  waiver_basis        :string(191)
#  pub_state           :string
#  software_license_id :integer
#  edit_code           :string(191)
#  import_info         :integer          default("other")
#
FactoryBot.define do

  factory :identifier, class: StashEngine::Identifier do

    identifier { Faker::Pid.doi }
    identifier_type { 'DOI' }
    storage_size { Faker::Number.number(digits: 5) }
    license_id { 'cc0' }

    transient do
      resources { 0 }
    end

    # Make sure the latest_resource_id is updated
    after(:create) do |identifier|
      identifier.shares = [build(:share, identifier_id: identifier.id)]
    end

  end

end
