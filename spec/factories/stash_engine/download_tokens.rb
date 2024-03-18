# == Schema Information
#
# Table name: stash_engine_download_tokens
#
#  id          :integer          not null, primary key
#  available   :datetime
#  token       :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_stash_engine_download_tokens_on_token  (token)
#
FactoryBot.define do

  factory :download_token, class: StashEngine::DownloadToken do
    resource

    token { Faker::Internet.uuid }
    available { Time.new + 60 }
  end
end
