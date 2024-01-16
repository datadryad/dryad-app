# == Schema Information
#
# Table name: stash_engine_authors
#
#  id                 :integer          not null, primary key
#  author_first_name  :string(191)
#  author_last_name   :string(191)
#  author_email       :string(191)
#  author_orcid       :string(191)
#  resource_id        :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  stripe_customer_id :text(65535)
#  author_order       :integer
#
FactoryBot.define do

  factory :author, class: StashEngine::Author do
    resource

    author_first_name { Faker::Name.first_name }
    author_last_name { Faker::Name.last_name }
    author_email { Faker::Internet.email }
    author_orcid { Faker::Pid.orcid }
    affiliations { [create(:affiliation)] }
  end

end
