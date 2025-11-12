# == Schema Information
#
# Table name: stash_engine_ror_orgs
#
#  id         :bigint           not null, primary key
#  ror_id     :string(191)
#  name       :string(191)
#  home_page  :string(191)
#  country    :string(191)
#  acronyms   :json
#  aliases    :json
#  isni_ids   :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
