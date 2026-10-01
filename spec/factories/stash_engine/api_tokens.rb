# == Schema Information
#
# Table name: stash_engine_api_tokens
#
#  id         :bigint           not null, primary key
#  expires_at :datetime
#  secret     :string(191)
#  token      :string(191)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  app_id     :string(191)
#
FactoryBot.define do

  factory :api_token, class: StashEngine::ApiToken do

    app_id { Faker::Internet.uuid }
    secret { Faker::Internet.uuid }
    token { Faker::Internet.uuid }
    expires_at { Time.new + 60 }
  end
end
