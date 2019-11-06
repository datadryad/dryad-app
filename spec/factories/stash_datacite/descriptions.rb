FactoryBot.define do

  factory :description, class: StashDatacite::Description do

    resource

    description_type { 'abstract' }
    description { Faker::Lorem.paragraph }

  end

end
