# == Schema Information
#
# Table name: stash_engine_journals
#
#  id                      :integer          not null, primary key
#  title                   :string(191)
#  issn                    :string(191)
#  website                 :string(191)
#  description             :text(65535)
#  payment_plan_type       :string
#  payment_contact         :string(191)
#  manuscript_number_regex :string(191)
#  stripe_customer_id      :string(191)
#  notify_contacts         :text(65535)
#  review_contacts         :text(65535)
#  allow_review_workflow   :boolean
#  allow_embargo           :boolean
#  allow_blackout          :boolean
#  default_to_ppr          :boolean          default(FALSE)
#  created_at              :datetime
#  updated_at              :datetime
#  journal_code            :string(191)
#  sponsor_id              :integer
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
