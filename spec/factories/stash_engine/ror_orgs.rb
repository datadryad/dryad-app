# == Schema Information
#
# Table name: stash_engine_ror_orgs
#
#  id         :bigint           not null, primary key
#  acronyms   :json
#  aliases    :json
#  country    :string(191)
#  home_page  :string(191)
#  isni_ids   :json
#  name       :string(191)
#  status     :integer          default("active")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ror_id     :string(191)
#
# Indexes
#
#  index_stash_engine_ror_orgs_on_status  (status)
#
FactoryBot.define do

  factory :ror_org, class: StashEngine::RorOrg do
    name { Faker::Company.name }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 7)}" }
    # Don't default to a real country, because we don't want it to accidentally match when testing
    country { 'The Undiscovered Country' }
    isni_ids { [] }
  end

end
