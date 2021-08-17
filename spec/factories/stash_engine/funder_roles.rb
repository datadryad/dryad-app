FactoryBot.define do

  factory :funder_role, class: StashEngine::FunderRole do

    user
    funder_id { "#{Faker::Name.initials(number: 4)}-#{Faker::Number.number(digits: 4)}" }
    funder_name { Faker::Company.name }
    role { 'admin' }

  end

end
