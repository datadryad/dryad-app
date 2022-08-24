FactoryBot.define do

  factory :api_token, class: StashEngine::ApiToken do

    app_id { Faker::Internet.uuid }
    secret { Faker::Internet.uuid }
    token { Faker::Internet.uuid }
    expires_at { Time.new + 60 }
  end
end