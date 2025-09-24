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
module StashEngine
  class ResourcePublication < ApplicationRecord
    self.table_name = 'stash_engine_resource_publications'
    has_paper_trail

    enum :pub_type, { primary_article: 0, preprint: 1 }

    validates :pub_type, uniqueness: { scope: :resource_id }
    # connecting a resource with the publication for a manuscript and/or a primary_article related_identifier
    belongs_to :resource
    belongs_to :journal_issn, class_name: 'StashEngine::JournalIssn', foreign_key: :publication_issn, optional: true
    belongs_to :manuscript, class_name: 'StashEngine::Manuscript', primary_key: :manuscript_number, foreign_key: :manuscript_number, optional: true
  end
end
