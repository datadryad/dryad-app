require 'stash/doi/id_gen'
require 'stash/payments/invoicer'
module StashEngine

  class CurationActivity < ApplicationRecord # rubocop:disable Metrics/ClassLength
    self.table_name = 'stash_engine_curation_activities'
    include StashEngine::Support::StringEnum

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
      processing
      submitted
      peer_review
      curation
      action_required
      withdrawn
      embargoed
      published
    ]
    string_enum('status', enum_vals, 'in_progress', false)

    # I'm making this more explicit because the view helper that did this was confusing and complex.
    # We also need to enforce states outside of the select list in the view.
    #
    # Note that setting the next state to the same as the current state is just to add a note and doesn't actually
    # change state in practice.  The UI may choose not to display the same state in the list, but it is allowed.
    CURATOR_ALLOWED_STATES = {
      in_progress: %w[in_progress],
      submitted: %w[submitted curation withdrawn peer_review],
      peer_review: %w[peer_review curation withdrawn],
      curation: (enum_vals - %w[in_progress submitted]),
      action_required: (enum_vals - %w[in_progress submitted]),
      withdrawn: %w[withdrawn curation],
      embargoed: %w[embargoed curation withdrawn published],
      published: (enum_vals - %w[in_progress submitted])
    }.with_indifferent_access.freeze

    # Validations
    # ------------------------------------------
    validates :resource, presence: true
    validates :status, presence: true, inclusion: { in: enum_vals }

    # Scopes
    # ------------------------------------------
    scope :latest, ->(resource:) {
      where(resource_id: resource.id).order(updated_at: :desc, id: :desc).first
    }

    # Callbacks
    # ------------------------------------------

    # Once we are certain that we will be publishing this dataset,
    # remove any "N/A" placeholders
    # Note tht this uses "after_validation" to ensure it runs before all of the "after_create"
    after_validation :remove_placeholder_funders, if: proc { |ca|
      (ca.published? || ca.embargoed?) && latest_curation_status_changed?
    }

    # the publication flags need to be set before creating datacite metadata (after create below)
    after_create :update_publication_flags, if: proc { |ca| %w[published embargoed peer_review withdrawn].include?(ca.status) }

    # When the status is published/embargoed send to Stripe and DataCite
    after_create do
      if !resource.skip_datacite_update &&
         (published? || embargoed?) &&
         latest_curation_status_changed?
        submit_to_datacite
        update_solr
        process_payment
        remove_peer_review
      end
    end

    after_create :copy_to_zenodo, if: proc { |ca|
      !ca.resource.skip_datacite_update && ca.published? && latest_curation_status_changed?
    }

    # Email the author and/or journal about status changes
    after_create :email_status_change_notices,
                 if: proc { |_ca| latest_curation_status_changed? && !resource.skip_emails }

    # Email invitations to register ORCIDs to authors when published
    after_create :email_orcid_invitations,
                 if: proc { |ca| ca.published? && latest_curation_status_changed? && !resource.skip_emails }

    after_create :update_salesforce_metadata, if: proc { |_ca|
                                                    latest_curation_status_changed? &&
                                                         CurationActivity.where(resource_id: resource_id).count > 1
                                                  }

    # Class methods
    # ------------------------------------------
    # Translates the enum value to a human readable status
    def self.readable_status(status)
      return '' unless status.present?

      case status
      when 'peer_review'
        'Private for peer review'
      when 'action_required'
        'Action required'
      else
        status.humanize
      end
    end

    # Instance methods
    # ------------------------------------------
    # Not sure why this uses splat? http://andrewberls.com/blog/post/naked-asterisk-parameters-in-ruby
    # maybe this calls super somehow and is useful for some reason, though I don't see it documented in the
    # ActiveModel::Serializers::JSON .
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

    def latest_curation_status_changed?
      last_two_statuses = CurationActivity.where(resource_id: resource_id).order(updated_at: :desc, id: :desc).limit(2)
      return true if last_two_statuses.count < 2 # no second-to-last status for this resource, it should be new to this resource

      last_two_statuses.first.status != last_two_statuses.second.status
    end

    def self.allowed_states(current_state)
      CURATOR_ALLOWED_STATES[current_state].dup
    end

    # Private methods
    # ------------------------------------------
    private

    # Callbacks
    # ------------------------------------------
    def process_payment
      return unless ready_for_payment?

      if resource.identifier&.user_must_pay?
        submit_to_stripe
      else
        resource.identifier&.record_payment
      end
    end

    def submit_to_stripe
      return unless ready_for_payment?

      inv = Stash::Payments::Invoicer.new(resource: resource, curator: user)
      inv.charge_user_via_invoice
    end

    def submit_to_datacite
      return unless should_update_doi?

      idg = Stash::Doi::IdGen.make_instance(resource: resource)
      idg.update_identifier_metadata!
      # Send out orcid invitations now that the citation has been registered
      email_orcid_invitations if published?
    rescue Stash::Doi::IdGenError => e
      Rails.logger.error "Stash::Doi::IdGen - Unable to submit metadata changes for : '#{resource&.identifier&.to_s}'"
      Rails.logger.error e.message
      StashEngine::UserMailer.error_report(resource, e).deliver_now
      raise e
    end

    def update_solr
      resource.submit_to_solr
    end

    def copy_to_zenodo
      resource.send_to_zenodo
      resource.send_software_to_zenodo(publish: true)
      resource.send_supp_to_zenodo(publish: true)
    end

    def remove_placeholder_funders
      return unless resource.present?

      resource.update(contributors: resource.contributors.reject { |funder| funder.contributor_name&.upcase == 'N/A' })
    end

    def remove_peer_review
      resource.hold_for_peer_review = false
      resource.peer_review_end_date = nil
      resource.save
    end

    # Triggered on a status change
    def email_status_change_notices
      return if previously_published?

      case status
      when 'published', 'embargoed'
        StashEngine::UserMailer.status_change(resource, status).deliver_now
        StashEngine::UserMailer.journal_published_notice(resource, status).deliver_now
      when 'peer_review'
        StashEngine::UserMailer.status_change(resource, status).deliver_now
        StashEngine::UserMailer.journal_review_notice(resource, status).deliver_now
      when 'submitted'

        # Don't send multiple emails for the same resource, or for submission made by curator
        return if previously_submitted?

        StashEngine::UserMailer.status_change(resource, status).deliver_now
      when 'withdrawn'
        return if note.include?('final action required reminder') # this has already gotten a special withdrawal email

        if user_id == 0
          StashEngine::UserMailer.user_journal_withdrawn(resource, status).deliver_now
        else
          StashEngine::UserMailer.status_change(resource, status).deliver_now
        end
      end
    end

    def previously_published?
      # ignoring the current CA, is there an embargoed or published status at any point for this identifier?
      prev_pub = false
      resource.identifier&.resources&.each do |res|
        res.curation_activities&.each do |ca|
          if (ca.id != id) && %w[published embargoed].include?(ca.status)
            prev_pub = true
            break
          end
        end
      end
      prev_pub
    end

    def previously_submitted?
      prev_sub = false
      # ignoring the current CA, is there a submitted status at any point for this resource?
      resource.curation_activities&.each do |ca|
        if (ca.id != id) && ca.submitted?
          prev_sub = true
          break
        end
      end
      # was this version submitted by a curator?
      prev_sub = true if user.curator?
      prev_sub
    end

    # Triggered on a status of :published
    def email_orcid_invitations
      return unless published?

      # Do not send an invitation to users who have no email address and do not have an
      # existing invitation for the identifier
      existing_invites = StashEngine::OrcidInvitation.where(identifier_id: resource.identifier_id).pluck(:email).uniq
      authors = resource.authors.where.not(author_email: existing_invites).where.not(author_email: nil).reject { |au| au&.author_email.blank? }

      return if authors.length <= 1

      authors[1..authors.length].each do |author|
        StashEngine::UserMailer.orcid_invitation(
          StashEngine::OrcidInvitation.create(
            email: author.author_email,
            identifier_id: resource.identifier_id,
            first_name: author.author_first_name,
            last_name: author.author_last_name,
            secret: SecureRandom.urlsafe_base64,
            invited_at: Time.new.utc
          )
        ).deliver_now
      end
    end

    def update_publication_flags
      case status
      when 'withdrawn'
        resource.update_columns(meta_view: false, file_view: false)
        target_pub_state = 'withdrawn'
      when 'peer_review'
        target_pub_state = 'unpublished'
      when 'embargoed'
        resource.update_columns(meta_view: true, file_view: false)
        target_pub_state = 'embargoed'
      when 'published'
        resource.update_columns(meta_view: true, file_view: true)
        target_pub_state = 'published'
      end

      return if resource&.identifier.nil?

      resource.identifier.update_column(:pub_state, target_pub_state)

      return if %w[withdrawn embargoed peer_review].include?(status)

      # find out if there were not file changes since last publication and reset file_view, if so.
      changed = false # want to see that none are changed
      resource.identifier.resources.reverse_each do |res|
        break if res.id != resource.id && res&.last_curation_activity&.status == 'published' # break once reached previous published

        if res.files_changed?(association: 'data_files')
          changed = true
          break
        end
      end
      resource.update_column(:file_view, false) unless changed # if nothing changed between previous published and this, don't view same files again
      resource.update_column(:file_view, false) unless resource.current_file_uploads.present?
    end

    def update_salesforce_metadata
      resource.update_salesforce_metadata
      true # ensure callbacks are not interrupted
    end

    # rubocop:enable

    # Helper methods
    # ------------------------------------------

    def ready_for_payment?
      resource&.identifier&.reload
      APP_CONFIG.payments&.service == 'stripe' &&
        (resource&.identifier&.payment_type.nil? ||
          resource&.identifier&.payment_type == 'unknown' ||
          resource&.identifier&.payment_type == 'waiver') &&
        (status == 'published' || status == 'embargoed')
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
