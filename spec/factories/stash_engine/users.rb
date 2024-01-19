# == Schema Information
#
# Table name: stash_engine_users
#
#  id               :integer          not null, primary key
#  first_name       :text(65535)
#  last_name        :text(65535)
#  email            :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  tenant_id        :text(65535)
#  last_login       :datetime
#  role             :string
#  orcid            :string(191)
#  migration_token  :string(191)
#  old_dryad_email  :string(191)
#  eperson_id       :integer
#  validation_tries :integer          default(0)
#  affiliation_id   :integer
#
FactoryBot.define do

  factory :user, class: StashEngine::User do

    first_name { Faker::Name.unique.first_name }
    last_name { Faker::Name.unique.last_name }
    email { Faker::Internet.unique.email }
    tenant_id { 'localhost' }
    role { 'user' }
    orcid { SecureRandom.hex }
    old_dryad_email { Faker::Internet.unique.email }
    eperson_id { rand(10_000) }
    validation_tries { 0 }

  end

end
