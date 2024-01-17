# == Schema Information
#
# Table name: stash_engine_api_tokens
#
#  id         :bigint           not null, primary key
#  app_id     :string(191)
#  secret     :string(191)
#  token      :string(191)
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do

  factory :api_token, class: StashEngine::ApiToken do

    app_id { Faker::Internet.uuid }
    secret { Faker::Internet.uuid }
    token { Faker::Internet.uuid }
    expires_at { Time.new + 60 }
  end
end
