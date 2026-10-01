# == Schema Information
#
# Table name: stash_engine_journal_organizations
#
#  id            :bigint           not null, primary key
#  contact       :string(191)
#  name          :string(191)
#  type          :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_org_id :integer
#
FactoryBot.define do

  factory :journal_organization, class: StashEngine::JournalOrganization do

    name { Faker::Company.name }
    type { 'publisher' }
    parent_org_id { nil }

  end

end
