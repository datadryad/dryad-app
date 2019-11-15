FactoryBot.define do

  factory :publisher, class: StashDatacite::Publisher do

    resource

    publisher { Faker::Company.name }

  end

end
