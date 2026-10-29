# == Schema Information
#
# Table name: stash_engine_tenant_ror_orgs
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ror_id     :string(191)
#  tenant_id  :string(191)
#
# Indexes
#
#  index_stash_engine_tenant_ror_orgs_on_tenant_id_and_ror_id  (tenant_id,ror_id)
#
FactoryBot.define do
  factory :tenant_ror_org, class: StashEngine::TenantRorOrg do
    tenant_id { 'mock_tenant' }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 7)}" }
  end
end
