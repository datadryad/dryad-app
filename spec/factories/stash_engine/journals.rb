FactoryBot.define do

  factory :journal, class: StashEngine::Journal do

    title { Faker::Company.industry }
    issn { "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" }
    journal_code { Faker::Name.initials(number: 4) }
  end

end
