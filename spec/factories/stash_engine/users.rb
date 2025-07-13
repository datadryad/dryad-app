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
#  tenant_auth_date :datetime
#  validated        :boolean          default(FALSE)
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
    transient do
      role { nil }
      role_object { nil }
    end

    first_name { Faker::Name.unique.first_name }
    last_name { Faker::Name.unique.last_name }
    email { Faker::Internet.unique.email }
    tenant_id { 'mock_tenant' }
    tenant_auth_date { Time.now }
    orcid { Faker::Pid.orcid }
    old_dryad_email { Faker::Internet.unique.email }
    eperson_id { rand(10_000) }
    validated { true }

    after(:create) do |user, e|
      create(:tenant, id: user.tenant_id) if user.tenant_id.present? && !StashEngine::Tenant.exists?(user.tenant_id)
      create(:role, user: user, role: e.role, role_object: e.role_object) if e.role.present?
    end
  end

end
