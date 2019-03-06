require 'stash/doi/id_gen'
require 'stash/payments/invoicer'

module StashEngine

  class CurationActivity < ActiveRecord::Base

    include StashEngine::Concerns::StringEnum

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
    #  :curation, :action_required, :published, :embargoed and :withdrawn are all manually
    #  set by the Curator on the Admin page.
    #
    #  :published   <-- Is set by the Curator via the UI OR automatically set when the
    #                   Resource's publication_date has reached maturity
    #
    enum_vals = %w[
      in_progress
      submitted
      peer_review
      curation
      action_required
      withdrawn
      embargoed
      published
    ]
    string_enum('status', enum_vals, 'in_progress', false)

    # Validations
    # ------------------------------------------
    validates :resource, presence: true
    validates :status, presence: true, inclusion: { in: enum_vals }

    # Scopes
    # ------------------------------------------
    scope :latest, ->(resource_id) {
      where(resource_id: resource_id).order(updated_at: :desc, id: :desc).first
    }

    # Callbacks
    # ------------------------------------------
    # When the status is published send to Stripe and DataCite
    after_save :submit_to_stripe, if: :ready_for_payment?
    after_create :submit_to_datacite, :update_solr, if: :published? || :embargoed?

    after_create :update_resource_reference!
    after_destroy :remove_resource_reference!

    # Class methods
    # ------------------------------------------
    # Translates the enum value to a human readable status
    def self.readable_status(status)
      case status
      when 'peer_review'
        'Private for Peer Review'
      when 'action_required'
        'Author Action Required'
      else
        status.humanize.split.map(&:capitalize).join(' ')
      end
    end

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

    # Local instance method that sends the current status to the class method
    # for translation
    def readable_status
      CurationActivity.readable_status(status)
    end

    # don't think the status_changed? method is right since it only detects a change in the same
    # activerecord row.  We're adding a new row for each item, so a create, not a change in value.
    def latest_curation_status_changed?
      last_two_statuses = CurationActivity.where(resource_id: resource_id).order(updated_at: :desc, id: :desc).limit(2)
      return true if last_two_statuses.count < 2 # no second-to-last status for this resource, it should be new to this resource
      last_two_statuses.first.status != last_two_statuses.second.status
    end

    # Private methods
    # ------------------------------------------
    private

    # Callbacks
    # ------------------------------------------
    def update_resource_reference!
      StashEngine::Resource.find(resource_id).update(current_curation_activity_id: id)
    end

    def remove_resource_reference!
      # Reverts the current_curation_activity pointer on Resource to the prior activity
      prior = CurationActivity.where(resource_id: resource_id).where.not(id: id).order(updated_at: :desc).first
      StashEngine::Resource.find(resource_id).update(current_curation_activity_id: prior&.id || '')
    end

    def submit_to_stripe
      # TODO: -- re-enable this with the chargeable logic
      # return unless resource.identifier&.chargeable?
      inv = Stash::Payments::Invoicer.new(resource: resource, curator: user)
      inv.charge_via_invoice
    end

    def submit_to_datacite
      return unless should_update_doi?
      idg = Stash::Doi::IdGen.make_instance(resource: resource)
      idg.update_identifier_metadata!
    end

    def update_solr
      return unless (published? || embargoed?) && latest_curation_status_changed?
      resource.submit_to_solr
    end

    # Helper methods
    # ------------------------------------------

    def ready_for_payment?
      !StashEngine.app.nil? &&
        StashEngine.app.payments.service == 'stripe' &&
        !resource.identifier.nil? &&
        resource.identifier.invoice_id.nil?
    end

    def should_update_doi?
      last_merritt_version = resource.identifier&.last_submitted_version_number
      return false if last_merritt_version.nil? # don't submit random crap to DataCite unless it's preserved in Merritt

      # only do UPDATEs with DOIs in production because ID updates like to fail in test EZID/DataCite because they delete their identifiers at random
      return false if last_merritt_version > 1 && Rails.env != 'production'
      true
    end

    def user_name
      return user.name unless user.nil?
      'System'
    end
  end
end
