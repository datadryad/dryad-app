FactoryBot.define do

  factory :journal_organization, class: StashEngine::JournalOrganization do

    name { Faker::Company.name }
    type { 'publisher' }

  end

end
