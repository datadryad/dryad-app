FactoryBot.define do
  factory :tenant_ror_org, class: StashEngine::TenantRorOrg do
    tenant_id { 'mock_tenant' }
    ror_id { "https://ror.org/#{Faker::Number.number(digits: 7)}" }
  end
end
