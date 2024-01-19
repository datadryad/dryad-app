# == Schema Information
#
# Table name: stash_engine_manuscripts
#
#  id                :bigint           not null, primary key
#  journal_id        :bigint
#  identifier_id     :bigint
#  manuscript_number :string(191)
#  status            :string(191)
#  metadata          :text(16777215)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
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
