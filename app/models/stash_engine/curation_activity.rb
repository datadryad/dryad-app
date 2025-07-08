# == Schema Information
#
# Table name: stash_engine_curation_activities
#
#  id          :integer          not null, primary key
#  deleted_at  :datetime
#  keywords    :string(191)
#  note        :text(65535)
#  status      :string(191)      default("in_progress")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#  user_id     :integer
#
# Indexes
#
#  index_stash_engine_curation_activities_on_deleted_at          (deleted_at)
#  index_stash_engine_curation_activities_on_resource_id_and_id  (resource_id,id)
#
require 'stash/doi/datacite_gen'
require 'stash/payments/invoicer'
module StashEngine

  class CurationActivity < ApplicationRecord # rubocop:disable Metrics/ClassLength
    self.table_name = 'stash_engine_curation_activities'
    acts_as_paranoid

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
    enum :status, enum_vals.index_by(&:to_sym), default: 'in_progress', validate: true

    # I'm making this more explicit because the view helper that did this was confusing and complex.
    # We also need to enforce states outside of the select list in the view.
    #
    # Note that setting the next state to the same as the current state is just to add a note and doesn't actually
    # change state in practice.  The UI may choose not to display the same state in the list, but it is allowed.
    CURATOR_ALLOWED_STATES = {
      in_progress: %w[in_progress],
      processing: %w[in_progress processing],
      submitted: %w[submitted curation withdrawn peer_review],
      peer_review: %w[peer_review submitted curation withdrawn],
      curation: (enum_vals - %w[in_progress submitted]),
      action_required: (enum_vals - %w[in_progress submitted]),
      withdrawn: %w[withdrawn curation],
      embargoed: %w[embargoed curation withdrawn published],
      published: (enum_vals - %w[in_progress submitted])
    }.with_indifferent_access.freeze

    # Validations
    # ------------------------------------------
    validates :resource, presence: true

    # Scopes
    # ------------------------------------------
    scope :latest, ->(resource:) {
      where(resource_id: resource.id).order(updated_at: :desc, id: :desc).first
    }

    # Callbacks
    # ------------------------------------------
    before_validation :set_resource

    after_create :process_dates, if: %i[curation_status_changed?]

    # the publication flags need to be set before creating datacite metadata (after create below)
    after_create :update_publication_flags, if: proc { |ca| %w[published embargoed peer_review withdrawn].include?(ca.status) }
    after_create :update_pub_state

    # When the status is published/embargoed send to Stripe and DataCite
    after_create :process_resource

    after_create :copy_to_zenodo, if: proc { |ca|
      !ca.resource.skip_datacite_update && ca.published? && curation_status_changed?
    }

    # Email the author and/or journal about status changes
    after_create :email_status_change_notices,
                 if: proc { |_ca| curation_status_changed? && !resource.skip_emails }

    # Email invitations to register ORCIDs to authors when published
    after_create :email_orcid_invitations,
                 if: proc { |ca| ca.published? && curation_status_changed? && !resource.skip_emails }

    after_create :update_salesforce_metadata, if: proc { |_ca|
      curation_status_changed? &&
        CurationActivity.where(resource_id: resource_id).count > 1
    }

    # Class methods
    # ------------------------------------------
    # Translates the enum value to a human readable status
    def self.readable_status(status)
      status = status.first if status.is_a?(Array)
      return '' unless status.present?

      case status
      when 'error'
        'Upload error'
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
    def set_resource
      self.resource = StashEngine::Resource.find_by(id: resource_id) if resource.blank?
    end

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

    def previous_status
      resource&.curation_activities&.where('id < ?', id)&.order(updated_at: :desc, id: :desc)&.last&.status
    end

    def curation_status_changed?
      return true if previous_status.blank?

      status != previous_status
    end

    def first_time_in_status?
      return false unless curation_status_changed?
      return true unless resource

      resource.curation_activities.where('id < ?', id).where(status: status).empty?
    end

    def self.allowed_states(current_state, current_user)
      statuses = CURATOR_ALLOWED_STATES[current_state].dup
      statuses << 'withdrawn' if current_user.superuser? # superusers can withdraw a datasets from any status
      statuses.uniq
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
      # after first publication, the dataset will be switched to new payment system
      return unless resource.identifier.old_payment_system

      resource.identifier.update(old_payment_system: false, last_invoiced_file_size: resource.total_file_size)
    end

    def submit_to_stripe
      return unless ready_for_payment?

      inv = Stash::Payments::Invoicer.new(resource: resource, curator: user)
      if resource.identifier.payment_type == 'stripe' && previously_published?
        inv.check_new_overages(resource.identifier.previous_invoiced_file_size)
      else
        inv.charge_user_via_invoice
      end
    end

    def submit_to_datacite
      return unless should_update_doi?

      idg = Stash::Doi::DataciteGen.new(resource: resource)
      idg.update_identifier_metadata!
      # Send out orcid invitations now that the citation has been registered
      email_orcid_invitations if published?
    rescue Stash::Doi::DataciteGenError => e
      logger.error "Stash::Doi::DataciteGen - Unable to submit metadata changes for : '#{resource&.identifier}'"
      logger.error e.message
      StashEngine::UserMailer.error_report(resource, e).deliver_now
      raise e
    end

    def update_solr
      resource.submit_to_solr
    end

    def process_dates
      update_dates = { last_status_date: created_at }
      # update delete_calculation_date if the status changed after the date set by the curators
      update_dates[:delete_calculation_date] = delete_calculation_date_value

      if first_time_in_status?
        case status
        when 'processing', 'peer_review', 'submitted', 'withdrawn'
          update_dates[status.to_sym] = created_at
        when 'curation'
          update_dates[:curation_start] = created_at
        when 'embargoed', 'published'
          update_dates[:approved] = created_at
        end
      end
      update_dates[:curation_end] = created_at if previous_status == 'curation' && resource.process_date.curation_end.blank?
      return if update_dates.empty?

      resource.process_date.update(update_dates)
      id_dates = update_dates.delete_if { |k, _v| resource.identifier.process_date.send(k).present? }
      resource.identifier.process_date.update(id_dates) unless id_dates.empty?
    end

    def process_resource
      logger.info("SKIP_PROCESS_RESOURCE due to 'skip_datacite_update'") and return if resource.skip_datacite_update
      logger.info("SKIP_PROCESS_RESOURCE due to 'published? #{published?} || embargoed? #{embargoed?}'") and return unless published? || embargoed?
      logger.info("SKIP_PROCESS_RESOURCE due to '!curation_status_changed?'") and return unless curation_status_changed?

      submit_to_datacite
      update_solr
      process_payment
      remove_peer_review
    end

    def copy_to_zenodo
      # Copy only software and supplemental files to zenodo | resource.send_to_zenodo
      resource.send_software_to_zenodo(publish: true)
      resource.send_supp_to_zenodo(publish: true)
    end

    def remove_peer_review
      resource.update(hold_for_peer_review: false, peer_review_end_date: nil)
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
        return unless first_time_in_status?

        StashEngine::UserMailer.status_change(resource, status).deliver_now unless user.min_curator?
      when 'withdrawn'
        return if note.include?('final action required reminder') # this has already gotten a special withdrawal email
        return if note.include?('notification that this item was set to `withdrawn`') # is automatic withdrawal action, no email required

        if user_id == 0
          StashEngine::UserMailer.user_journal_withdrawn(resource, status).deliver_now
        else
          StashEngine::UserMailer.status_change(resource, status).deliver_now
        end
      end
    end

    def previously_published?
      return false unless resource

      # ignoring the current CA, is there an embargoed or published status at any point for this identifier?
      resource.identifier.resources.map(&:curation_activities).flatten.reject { |ca| ca.id == id }
        .map(&:status).intersect?(%w[published embargoed]) || false
    end

    # Triggered on a status of :published
    def email_orcid_invitations
      return unless published?

      # Do not send an invitation to users who have no email address or have an
      # existing invitation for the identifier
      existing_invites = StashEngine::OrcidInvitation.where(identifier_id: resource.identifier_id).pluck(:email).uniq
      authors = resource.authors.where.not(author_email: existing_invites).where.not(author_email: nil).to_a
      authors = authors.delete_if { |au| au&.author_email.blank? }

      return if authors.empty?

      authors.each do |author|
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
      when 'embargoed'
        resource.update_columns(meta_view: true, file_view: false)
      when 'published'
        resource.update_columns(meta_view: true, file_view: true)
      end

      return if resource&.identifier.nil?
      return if %w[withdrawn embargoed peer_review].include?(status)

      # find out if there were no file changes since last publication and reset file_view, if so.
      changed = false # want to see that none are changed
      resource.previous_resources(include_self: true).each do |res|
        break if res.id != resource.id && res&.last_curation_activity&.status == 'published' # break once reached previous published

        next unless res.files_changed?(association: 'data_files')

        changed = true
        break
      end
      resource.update_column(:file_view, false) unless changed # if nothing changed between previous published and this, don't view same files again
      resource.update_column(:file_view, false) unless resource.current_file_uploads.present?
    end

    def update_pub_state
      PubStateService.new(resource.identifier).update_for_ca_status(status)
    end

    def update_salesforce_metadata
      resource.update_salesforce_metadata
      true # ensure callbacks are not interrupted
    end

    # rubocop:enable

    # Helper methods
    # ------------------------------------------

    def ready_for_payment?
      return false unless resource
      return false unless resource.identifier

      resource.identifier.reload
      return false unless resource.identifier.old_payment_system
      return false unless first_time_in_status?

      APP_CONFIG&.payments&.service == 'stripe' &&
        (resource.identifier.payment_type.nil? || %w[unknown waiver stripe].include?(resource.identifier.payment_type)) &&
        %w[published embargoed].include?(status)
    end

    def should_update_doi?
      last_repo_version = resource&.identifier&.last_submitted_version_number
      # don't submit random crap to DataCite unless it's preserved
      logger.info("SKIP_DOI_UPDATE due to 'last_repo_version' #{last_repo_version}") and return false if last_repo_version.nil?

      # only do UPDATES with DOIs in production because ID updates like to fail in test DataCite because they delete their identifiers at random
      if last_repo_version > 1 && APP_CONFIG[:identifier_service][:prefix] == '10.7959'
        logger.info("SKIP_DOI_UPDATE due to 'last_repo_version' #{last_repo_version} && #{APP_CONFIG[:identifier_service][:prefix]}") and return false
      end

      true
    end

    def user_name
      return user.name unless user.nil?

      'System'
    end

    def delete_calculation_date_value
      existing_date = resource.identifier.process_date[:delete_calculation_date]
      return created_at if existing_date.blank?

      [created_at, existing_date].max
    end
  end
end
