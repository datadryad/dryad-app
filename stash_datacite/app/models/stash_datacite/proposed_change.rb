module StashEngine
  class ProposedChange < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id'

    CROSSREF_PUBLISHED_MESSAGE = 'reported that the related journal has been published'.freeze
    CROSSREF_UPDATE_MESSAGE = 'provided additional metadata'.freeze

    def approve!(current_user:)
      return false unless current_user.is_a?(StashEngine::User)

      cr = Stash::Import::Crossref.from_proposed_change(proposed_change: self)
      resource = cr.populate_resource
      add_metadata_updated_curation_note(cr.class.name.downcase.split('::').last, resource)
      resource.save
      resource.identifier.save
      update(approved: true, user_id: current_user.id)
      true
    end

    def reject!
      destroy
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
