# == Schema Information
#
# Table name: stash_engine_resource_publications
#
#  id                :bigint           not null, primary key
#  manuscript_number :string(191)
#  publication_issn  :string(191)
#  publication_name  :string(191)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  resource_id       :integer
#
# Indexes
#
#  index_stash_engine_resource_publications_on_resource_id  (resource_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (resource_id => stash_engine_resources.id)
#
FactoryBot.define do

  factory :resource_publication, class: StashEngine::ResourcePublication do
    publication_name { Faker::Company.industry }
  end
end
