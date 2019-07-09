module StashEngine
  class ProposedChange < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id'

    CROSSREF_PUBLISHED_MESSAGE = 'reported that the related journal has been published'.freeze
    CROSSREF_UPDATE_MESSAGE = 'provided additional metadata'.freeze

    # Overriding equality check to make sure we're only comparing the fields we care about
    # rubocop:disable Metrics/CyclomaticComplexity
    def ==(other)
      return false unless other.present? && other.is_a?(StashEngine::ProposedChange)

      other.identifier_id == identifier_id && other.authors == authors && other.provenance == provenance &&
        other.publication_date == publication_date && other.publication_issn == publication_issn &&
        other.publication_doi == publication_doi && other.publication_name == publication_name &&
        other.title == title
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def approve!(current_user:)
      return false if current_user.blank? || !current_user.is_a?(StashEngine::User)

      cr = Stash::Import::Crossref.from_proposed_change(proposed_change: self)
      resource = cr.populate_resource
      add_metadata_updated_curation_note(cr.class.name.downcase.split('::').last, resource)
      resource.save
      resource.identifier.save
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
        user_id: resource.current_curation_activity.user_id,
        status: resource.current_curation_status,
        note: "#{provenance.capitalize} #{CROSSREF_UPDATE_MESSAGE}"
      )
    end

  end
end
