FactoryBot.define do

  factory :share, class: StashEngine::Share do
    resource

    secret_id { SecureRandom.uuid }

    transient do
      tenant { 'dryad' }
    end
  end

end
