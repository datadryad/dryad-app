# == Schema Information
#
# Table name: stash_engine_download_tokens
#
#  id          :integer          not null, primary key
#  resource_id :integer
#  token       :string(191)
#  available   :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do

  factory :download_token, class: StashEngine::DownloadToken do
    resource

    token { Faker::Internet.uuid }
    available { Time.new + 60 }
  end
end
