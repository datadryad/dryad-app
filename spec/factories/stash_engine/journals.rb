# == Schema Information
#
# Table name: stash_engine_journals
#
#  id                      :integer          not null, primary key
#  allow_blackout          :boolean
#  allow_embargo           :boolean
#  allow_review_workflow   :boolean
#  default_to_ppr          :boolean          default(FALSE)
#  description             :text(65535)
#  issn                    :string(191)
#  journal_code            :string(191)
#  manuscript_number_regex :string(191)
#  notify_contacts         :text(65535)
#  payment_contact         :string(191)
#  payment_plan_type       :string
#  review_contacts         :text(65535)
#  title                   :string(191)
#  website                 :string(191)
#  created_at              :datetime
#  updated_at              :datetime
#  sponsor_id              :integer
#  stripe_customer_id      :string(191)
#
# Indexes
#
#  index_stash_engine_journals_on_issn   (issn)
#  index_stash_engine_journals_on_title  (title)
#
FactoryBot.define do

  factory :journal, class: StashEngine::Journal do

    title { Faker::Company.industry }
    issn do
      ["#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}",
       "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"]
    end
    journal_code { Faker::Name.initials(number: 4) }
  end

end
