FactoryBot.define do

  factory :journal_issn, class: StashEngine::JournalIssn do

    id { "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" }

  end

end
