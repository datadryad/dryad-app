# == Schema Information
#
# Table name: stash_engine_email_tokens
#
#  id         :bigint           not null, primary key
#  expires_at :datetime
#  token      :string(191)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tenant_id  :string(191)
#  user_id    :integer
#
FactoryBot.define do

  factory :email_token, class: StashEngine::EmailToken do
    user

    token { Faker::Internet.uuid }
    expires_at { Time.new + 60 }
  end
end
