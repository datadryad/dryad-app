FactoryBot.define do

  factory :download_token, class: StashEngine::DownloadToken do
    resource

    token { Faker::Internet.uuid }
    available { Time.new + 60 }
  end
end