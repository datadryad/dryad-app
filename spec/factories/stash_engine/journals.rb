# == Schema Information
#
# Table name: stash_engine_journals
#
#  id                      :integer          not null, primary key
#  allow_review_workflow   :boolean          default(TRUE)
#  api_contacts            :text(65535)
#  default_to_ppr          :boolean          default(FALSE)
#  description             :text(65535)
#  journal_code            :string(191)
#  manuscript_number_regex :string(191)
#  notify_contacts         :text(65535)
#  old_covers_ldf          :boolean          default(FALSE)
#  old_payment_plan_type   :string
#  peer_review_custom_text :text(65535)
#  preprint_server         :boolean          default(FALSE)
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
#  index_stash_engine_journals_on_title  (title)
#
FactoryBot.define do

  factory :journal, class: StashEngine::Journal do
    transient do
      issn { nil }
    end

    title { Faker::Company.unique.industry }
    journal_code { Faker::Name.initials(number: 4) }
    sponsor_id { nil }

    after(:create) do |journal, e|
      if e.issn.present?
        if e.issn.is_a?(Array)
          e.issn.each { |id| create(:journal_issn, journal_id: journal.id, id: id) }
        else
          create(:journal_issn, journal_id: journal.id, id: e.issn)
        end
      else
        create(:journal_issn, journal_id: journal.id)
      end
      journal.reload
    end
  end

end
