require 'stash/doi/id_gen'
require 'stash/payments/invoicer'
module StashEngine

  class CurationActivity < ActiveRecord::Base # rubocop:disable Metrics/ClassLength

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
    # When the status is published/embargoed send to Stripe and DataCite
    after_create :submit_to_datacite, :update_solr, :submit_to_stripe, :remove_peer_review,
                 if: proc { |ca|
                       !ca.resource.skip_datacite_update && (ca.published? || ca.embargoed?) &&
                                 latest_curation_status_changed?
                     }

    # Email the author and/or journal about status changes
    after_create :email_status_change_notices,
                 if: proc { |_ca| latest_curation_status_changed? && !resource.skip_emails }

    # Email invitations to register ORCIDs to authors when published
    after_create :email_orcid_invitations,
                 if: proc { |ca| ca.published? && latest_curation_status_changed? && !resource.skip_emails }

    after_create :update_publication_flags, if: proc { |ca| %w[published embargoed withdrawn].include?(ca.status) }

    # Class methods
    # ------------------------------------------
    # Translates the enum value to a human readable status
    def self.readable_status(status)
      return '' unless status.present?
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
    def submit_to_stripe
      return unless ready_for_payment? &&
                    resource.identifier&.user_must_pay?

      inv = Stash::Payments::Invoicer.new(resource: resource, curator: user)
      inv.charge_user_via_invoice
    end

    def submit_to_datacite
      return unless should_update_doi?
      idg = Stash::Doi::IdGen.make_instance(resource: resource)
      idg.update_identifier_metadata!
      # Send out orcid invitations now that the citation has been registered
      email_orcid_invitations if published?
    rescue Stash::Doi::IdGenError => ige
      Rails.logger.error "Stash::Doi::IdGen - Unable to submit metadata changes for : '#{resource&.identifier&.to_s}'"
      Rails.logger.error ige.message
      StashEngine::UserMailer.error_report(resource, ige).deliver_now
      raise ige
    end

    def update_solr
      resource.submit_to_solr
    end

    def remove_peer_review
      resource.hold_for_peer_review = false
      resource.save
    end

    # Triggered on a status change
    def email_status_change_notices
      return if previously_published?

      case status
      when 'published'
        StashEngine::UserMailer.status_change(resource, status).deliver_now
        StashEngine::UserMailer.journal_published_notice(resource, status).deliver_now
      when 'embargoed'
        StashEngine::UserMailer.status_change(resource, status).deliver_now
        StashEngine::UserMailer.journal_published_notice(resource, status).deliver_now
      when 'peer_review'
        StashEngine::UserMailer.status_change(resource, status).deliver_now
        StashEngine::UserMailer.journal_review_notice(resource, status).deliver_now
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

    # Triggered on a status of :published
    # rubocop:disable Metrics/AbcSize
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

    # rubocop:disable Metrics/CyclomaticComplexity
    def update_publication_flags
      case status
      when 'withdrawn'
        resource.update_columns(meta_view: false, file_view: false)
      when 'embargoed'
        resource.update_columns(meta_view: true, file_view: false)
      when 'published'
        resource.update_columns(meta_view: true, file_view: true)
      end

      return if resource&.identifier.nil?

      resource.identifier.update_column(:pub_state, status)

      return if %w[withdrawn embargoed].include?(status)

      # find out if there were not file changes since last publication and reset file_view, if so.
      changed = false # want to see that none are changed
      resource.identifier.resources.reverse_each do |res|
        break if res.id != resource.id && res&.current_curation_activity&.status == 'published' # break once reached previous published
        if res.files_changed?
          changed = true
          break
        end
      end
      resource.update_column(:file_view, false) unless changed # if nothing changed between previous published and this, don't view same files again
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity

    # Helper methods
    # ------------------------------------------

    def ready_for_payment?
      StashEngine.app&.payments&.service == 'stripe' &&
        resource&.identifier&.invoice_id.nil? &&
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
