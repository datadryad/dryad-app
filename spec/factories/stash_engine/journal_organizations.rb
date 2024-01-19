# == Schema Information
#
# Table name: stash_engine_journal_organizations
#
#  id            :bigint           not null, primary key
#  name          :string(191)
#  contact       :string(191)
#  parent_org_id :integer
#  type          :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do

  factory :journal_organization, class: StashEngine::JournalOrganization do

    name { Faker::Company.name }
    type { 'publisher' }

  end

end
