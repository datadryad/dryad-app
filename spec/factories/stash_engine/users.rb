FactoryBot.define do
  factory :user do
    first_name { Faker::Name.unique.first_name }
    last_name { Faker::Name.unique.last_name }
    email { Faker::Internet.unique.safe_email }
    tenant_id { 'localhost' }
    role { 'user' }
    orcid { SecureRandom.hex }
    migration_token { SecureRandom.hex }
    old_dryad_email { Faker::Internet.unique.safe_email }
    epserson_id { rand(10_000) }
    validation_tries { 0 }
    type { [0,1].sample }
  end
end