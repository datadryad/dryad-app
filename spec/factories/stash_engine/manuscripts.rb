# == Schema Information
#
# Table name: stash_engine_manuscripts
#
#  id                :bigint           not null, primary key
#  manuscript_number :string(191)
#  metadata          :text(16777215)
#  status            :string(191)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  identifier_id     :bigint
#  journal_id        :bigint
#
# Indexes
#
#  index_stash_engine_manuscripts_on_identifier_id  (identifier_id)
#  index_stash_engine_manuscripts_on_journal_id     (journal_id)
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
        'keywords' => [Faker::Hipster.word, Faker::Hipster.word] }
    end
  end

end
