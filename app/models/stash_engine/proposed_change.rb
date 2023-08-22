require 'stash/import/crossref'

module StashEngine
  class ProposedChange < ApplicationRecord
    self.table_name = 'stash_engine_proposed_changes'
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id', optional: true

    CROSSREF_PUBLISHED_MESSAGE = 'reported that the related journal has been published'.freeze
    CROSSREF_UPDATE_MESSAGE = 'provided additional metadata'.freeze

    # Overriding equality check to make sure we're only comparing the fields we care about
    def ==(other)
      return false unless other.present? && other.is_a?(StashEngine::ProposedChange)

      other.identifier_id == identifier_id && other.provenance == provenance &&
        other.publication_issn == publication_issn && other.publication_doi == publication_doi &&
        other.publication_name == publication_name && other.title == title
    end

    def approve!(current_user:, approve_type: )
      # values are primary, primary_no_metadata, preprint, preprint_no_metadata, related, related_no_metadata
      dropdown_to_type = {primary: 'primary_article', related: 'article', preprint: 'preprint'}.with_indifferent_access

      bare_approve_type = approve_type.to_s.gsub('_no_metadata', '')
      return false if dropdown_to_type[bare_approve_type].blank?

      article_type = dropdown_to_type[bare_approve_type]
      update_type = ( approve_type.to_s.end_with?('_no_metadata') ? 'relationship' : 'metadata' )

      return false if current_user.blank? || !current_user.is_a?(StashEngine::User)

      cr = Stash::Import::Crossref.from_proposed_change(proposed_change: self)
      resource = cr.populate_pub_update!(article_type: article_type, update_type: update_type)

      add_metadata_updated_curation_note(cr.class.name.downcase.split('::').last, resource)
      update(approved: true, user_id: current_user.id)
      true
    end

    def reject!(current_user:)
      return false if current_user.blank? || !current_user.is_a?(StashEngine::User)

      update(rejected: true, user_id: current_user.id)
      true
    end

    private

    def add_metadata_updated_curation_note(provenance, resource)
      resource.curation_activities << StashEngine::CurationActivity.new(
        user_id: 0, # system user
        status: resource.current_curation_status,
        note: "#{provenance.capitalize} #{CROSSREF_UPDATE_MESSAGE}"
      )
    end

  end
end
