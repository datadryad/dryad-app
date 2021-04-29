FactoryBot.define do

  factory :manuscript, class: StashEngine::Manuscript do
    journal
    identifier

    manuscript_number { "ms-#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" }
    status { 'accepted' }
    metadata do
      { 'ms title' => Faker::Hipster.sentence,
        'abstract' => Faker::Hipster.paragraph,
        'keywords' => [Faker::Educator.subject, Faker::Educator.subject] }
    end
  end

end
