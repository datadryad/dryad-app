# == Schema Information
#
# Table name: stash_engine_users
#
#  id               :integer          not null, primary key
#  email            :text(65535)
#  first_name       :text(65535)
#  last_login       :datetime
#  last_name        :text(65535)
#  migration_token  :string(191)
#  old_dryad_email  :string(191)
#  orcid            :string(191)
#  role             :string
#  validation_tries :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  affiliation_id   :integer
#  eperson_id       :integer
#  tenant_id        :text(65535)
#
# Indexes
#
#  index_stash_engine_users_on_affiliation_id  (affiliation_id)
#  index_stash_engine_users_on_email           (email)
#  index_stash_engine_users_on_orcid           (orcid)
#  index_stash_engine_users_on_tenant_id       (tenant_id)
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
