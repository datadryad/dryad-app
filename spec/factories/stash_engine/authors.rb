# == Schema Information
#
# Table name: stash_engine_authors
#
#  id                 :integer          not null, primary key
#  author_email       :string(191)
#  author_first_name  :string(191)
#  author_last_name   :string(191)
#  author_orcid       :string(191)
#  author_order       :integer
#  author_org_name    :string(255)
#  corresp            :boolean          default(FALSE)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  resource_id        :integer
#  stripe_customer_id :text(65535)
#
# Indexes
#
#  index_stash_engine_authors_on_author_orcid  (author_orcid)
#  index_stash_engine_authors_on_resource_id   (resource_id)
#
FactoryBot.define do

  factory :author, class: StashEngine::Author do
    resource

    author_first_name { Faker::Name.first_name }
    author_last_name { Faker::Name.last_name }
    author_email { Faker::Internet.email }
    author_orcid { Faker::Pid.orcid }
    corresp { true }

    after(:create) do |record|
      record.affiliations << create(:affiliation)
    end
  end
end
