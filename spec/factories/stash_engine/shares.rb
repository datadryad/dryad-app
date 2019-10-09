FactoryBot.define do

  factory :share, class: StashEngine::Share do
    identifier

    secret_id { SecureRandom.uuid }
  end

end
