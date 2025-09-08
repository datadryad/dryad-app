# == Schema Information
#
# Table name: stash_engine_proposed_changes
#
#  id               :integer          not null, primary key
#  approved         :boolean
#  authors          :text(65535)
#  provenance       :string(191)
#  provenance_score :float(24)
#  publication_date :datetime
#  publication_doi  :string(191)
#  publication_issn :string(191)
#  publication_name :string(191)
#  rejected         :boolean
#  score            :float(24)
#  subjects         :text(65535)
#  title            :text(65535)
#  url              :string(191)
#  xref_type        :string(191)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  identifier_id    :integer
#  user_id          :integer
#
# Indexes
#
#  index_stash_engine_proposed_changes_on_identifier_id     (identifier_id)
#  index_stash_engine_proposed_changes_on_publication_doi   (publication_doi)
#  index_stash_engine_proposed_changes_on_publication_issn  (publication_issn)
#  index_stash_engine_proposed_changes_on_publication_name  (publication_name)
#  index_stash_engine_proposed_changes_on_user_id           (user_id)
#
require 'stash/import/crossref'

module StashEngine
  class ProposedChange < ApplicationRecord
    include PublicationMixin

    self.table_name = 'stash_engine_proposed_changes'
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    has_one :latest_resource, class_name: 'StashEngine::Resource', through: :identifier
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id', optional: true

    scope :processed, -> { where('approved = true OR rejected = true') }
    scope :unprocessed, -> { where(approved: false, rejected: false) }
    # Unprocessed and the DOI is not already in the resource
    scope :unmatched,
          -> {
            unprocessed.joins(:latest_resource).joins("
              LEFT OUTER JOIN `dcs_related_identifiers` ON `dcs_related_identifiers`.`resource_id` = `stash_engine_resources`.`id` AND
              REGEXP_SUBSTR(`dcs_related_identifiers`.`related_identifier`, '(10..+)') = `stash_engine_proposed_changes`.`publication_doi`
            ").where('`dcs_related_identifiers`.`id` IS NULL')
          }

    CROSSREF_PUBLISHED_MESSAGE = 'reported that the related manuscript has been accepted'.freeze
    CROSSREF_UPDATE_MESSAGE = 'provided information about a'.freeze

    # Overriding equality check to make sure we're only comparing the fields we care about
    def ==(other)
      return false unless other.present? && other.is_a?(StashEngine::ProposedChange)

      other.identifier_id == identifier_id && other.provenance == provenance &&
        other.publication_issn == publication_issn && other.publication_doi == publication_doi &&
        other.publication_name == publication_name && other.title == title
    end

    def dropdown_to_type
      { primary: 'primary_article', related: 'article', preprint: 'preprint' }.with_indifferent_access
    end

    def approve!(current_user:, approve_type:)
      article_type = dropdown_to_type[approve_type]
      prim_art = latest_resource.related_identifiers.primary_article.first

      if article_type == 'primary_article' && prim_art.present?
        prim_art.update(related_identifier: StashDatacite::RelatedIdentifier.standardize_doi(publication_doi))
      else
        latest_resource.related_identifiers << StashDatacite::RelatedIdentifier.create(
          related_identifier: StashDatacite::RelatedIdentifier.standardize_doi(publication_doi),
          related_identifier_type: 'doi',
          work_type: article_type,
          relation_type: 'iscitedby'
        )
      end

      unless article_type == 'article'
        cr = Stash::Import::Crossref.from_proposed_change(proposed_change: self)
        cr.populate_pub_update!(article_type)
      end

      if article_type == 'primary_article'
        identifier.record_payment if latest_resource.submitted? && identifier.publication_date.blank?
        release_resource(latest_resource) if latest_resource.current_curation_status == 'peer_review'
      end

      add_curation_note(latest_resource, approve_type)
      DataciteService.new(latest_resource).submit if latest_resource.current_curation_status == 'published'

      update(approved: true, user_id: current_user.id)
    end

    def reject!(current_user:)
      update(rejected: true, user_id: current_user.id)
    end

    private

    def add_curation_note(resource, type)
      CurationService.new(
        resource: resource,
        user_id: 0, # system user
        status: resource.current_curation_status,
        note: "Crossref #{CROSSREF_UPDATE_MESSAGE} #{type} article"
      ).process
    end
  end
end
