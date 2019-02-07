module StashEngine

  class CurationActivity < ActiveRecord::Base

    include StashEngine::StringEnum

    # Associations
    # ------------------------------------------
    belongs_to :resource, class_name: 'StashEngine::Resource', foreign_key: 'resource_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id'

    # Explanation of statuses
    #  :in_progress <-- When the resource's current resource_state != 'submitted'
    #                  This is the initial default value set on initialize
    #
    #  :submitted   <-- When the resource's current resource_state == 'submitted'
    #                  This is set by a callback on ResourceState.save
    #
    #  :curation, :action_required, :embargoed, :published and :withdrawn are
    #  all manually set by the Curator on the Admin page.
    #
    #  :published   <-- Is also automatically set when the Embargo's publication_date
    #                  has reached maturity
    #  :unchanged   <-- Automatically set when a Curator adds a note to on the Admin
    #                   activity page
    enum_vals = %w[
      in_progress
      submitted
      peer_review
      curation
      action_required
      embargoed
      published
      withdrawn
      unchanged
    ]
    string_enum('status', enum_vals, 'in_progress', false)

    # Validations
    # ------------------------------------------
    validates :resource, presence: true

    # Scopes
    # ------------------------------------------
    scope :latest, ->(resource_id) {
      where(resource_id: resource_id).where.not(status: 'unchanged').order(id: :desc).first
    }

    # Callbacks
    # ------------------------------------------
    after_save :submit_to_stripe, :submit_to_datacite

    # Instance methods
    # ------------------------------------------
    def as_json(*)
      # {"id":11,"identifier_id":1,"status":"Submitted","user_id":1,"note":"hello hello ssdfs2232343","keywords":null}
      {
        id: id,
        dataset: resource.identifier.to_s,
        status: readable_status,
        action_taken_by: user_name,
        note: note,
        keywords: keywords,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    # Translates the enum value to a human readable status
    def readable_status
      if peer_review?
        'Private for Peer Review'
      elsif action_required?
        'Author Action Required'
      elsif unchanged?
        'Status Unchanged'
      else
        status.humanize
      end
    end

    # Private methods
    # ------------------------------------------
    private

    # Callbacks
    # ------------------------------------------
    def submit_to_stripe
      # Should also check the statuses in the line below so we don't resubmit charges!
      #   e.g. Check the status flags on this object unless we're storing a boolean
      #        somewhere that records that we've already charged them.
      #   `return unless identifier.has_journal? && self.published?`
      return unless resource.identifier&.chargeable?
      # Call the stripe API
    end

    def submit_to_datacite
      return unless should_update_doi?
      idg = Stash::Doi::IdGen.make_instance(resource: resource)
      idg.update_identifier_metadata!
    end

    # Helper methods
    # ------------------------------------------

    # rubocop:disable Metrics/CyclomaticComplexity
    def should_update_doi?
      # only update if status changed or newly published or embargoed
      return false unless status_changed? && (published? || embargoed?)

      last_merritt_version = resource.identifier&.last_submitted_version_number
      return false if last_merritt_version.nil? # don't submit random crap to DataCite unless it's preserved in Merritt

      # only do UPDATEs with DOIs in production because ID updates like to fail in test EZID/DataCite because they delete their identifiers at random
      return false if last_merritt_version > 1 && Rails.env != 'production'
      true
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def user_name
      return user.name unless user.nil?
      'System'
    end
  end
end
