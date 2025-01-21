# == Schema Information
#
# Table name: stash_engine_resource_publications
#
#  id                :bigint           not null, primary key
#  manuscript_number :string(191)
#  pub_type          :integer          default("primary_article")
#  publication_issn  :string(191)
#  publication_name  :string(191)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  resource_id       :integer
#
# Indexes
#
#  index_resource_pub_type  (resource_id,pub_type) UNIQUE
#
FactoryBot.define do

  factory :resource_publication, class: StashEngine::ResourcePublication do
    publication_name { Faker::Company.industry }
  end
end
