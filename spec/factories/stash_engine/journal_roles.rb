FactoryBot.define do

  factory :journal_role, class: StashEngine::JournalRole do

    journal
    user

  end

end
