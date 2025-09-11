class CurationService

  # rubocop:disable Metrics/ParameterLists
  attr_reader :resource, :resource_id, :status, :user, :user_id, :note, :options
  def initialize(status:, resource: nil, resource_id: nil, user: nil, user_id: nil, note: nil, options: nil, created_at: nil)
    # rubocop:enable Metrics/ParameterLists
    @resource = resource || StashEngine::Resource.find_by(id: resource_id)
    @status = status
    @user = user.presence || StashEngine::User.find_by(id: user_id).presence || StashEngine::User.system_user
    @note = note
    @options = options
    @activity = StashEngine::CurationActivity.new(
      resource: @resource, status: @status, user: @user, note: @note,
      created_at: created_at || Time.now.utc
    )
  end

  def process
    @activity.save
    @skip_emails = @options&.dig(:skip_emails) || @resource.skip_emails || false

    update_pub_state
    update_publication_flags
    if @activity.curation_status_changed?
      process_dates
      process_resource if @activity.published? || @activity.embargoed?
      unless @skip_emails
        email_status_change_notices
        email_orcid_invitations if @activity.published?
      end
      update_salesforce_metadata if @resource.curation_activities.count > 1
    end

    @resource.identifier.reload
    @activity
  end

  private

  def copy_to_zenodo
    # Copy only software and supplemental files to zenodo
    @resource.send_software_to_zenodo(publish: true)
    @resource.send_supp_to_zenodo(publish: true)
  end

  def email_orcid_invitations
    return unless @activity.published?

    # Do not send an invitation to users who have no email address or have an
    # existing invitation for the identifier
    existing_invites = StashEngine::OrcidInvitation.where(identifier_id: @resource.identifier_id).pluck(:email).uniq
    authors = @resource.authors.where.not(author_email: existing_invites << nil).where(author_orcid: ['', nil]).to_a
    authors = authors.delete_if { |au| au&.author_email.blank? }

    return if authors.empty?

    authors.each do |author|
      StashEngine::UserMailer.orcid_invitation(
        StashEngine::OrcidInvitation.create(
          email: author.author_email,
          identifier_id: @resource.identifier_id,
          first_name: author.author_first_name,
          last_name: author.author_last_name,
          secret: SecureRandom.urlsafe_base64,
          invited_at: Time.new.utc
        )
      ).deliver_now
    end
  end

  def email_status_change_notices
    return if @activity.previously_published?

    case @status
    when 'published', 'embargoed'
      StashEngine::UserMailer.status_change(@resource, @status).deliver_now
      StashEngine::UserMailer.journal_published_notice(@resource, @status).deliver_now
    when 'peer_review'
      StashEngine::UserMailer.status_change(@resource, @status).deliver_now
      StashEngine::UserMailer.journal_review_notice(@resource, @status).deliver_now
    when 'submitted'
      # Don't send multiple emails for the same resource, or for submission made by curator
      return unless @activity.first_time_in_status?

      StashEngine::UserMailer.status_change(@resource, @status).deliver_now unless @user.min_curator?
    when 'withdrawn'
      return if @note&.include?('final action required reminder') # this has already gotten a special withdrawal email
      return if @note&.include?('notification that this item was set to `withdrawn`') # is automatic withdrawal action, no email required

      if @user.id == 0
        StashEngine::UserMailer.user_journal_withdrawn(@resource, @status).deliver_now
      else
        StashEngine::UserMailer.status_change(@resource, @status).deliver_now
      end
    end
  end

  def process_dates
    update_dates = { last_status_date: @activity.created_at }
    # update delete_calculation_date if the status changed after the date set by the curators
    update_dates[:delete_calculation_date] = @activity.delete_calculation_date_value

    if @activity.first_time_in_status?
      case @status
      when 'processing', 'peer_review', 'submitted', 'withdrawn'
        update_dates[@status.to_sym] = @activity.created_at
      when 'curation'
        update_dates[:curation_start] = @activity.created_at
      when 'embargoed', 'published', 'to_be_published'
        update_dates[:approved] = @activity.created_at
      end
    end
    update_dates[:curation_end] = @activity.created_at if @activity.previous_status == 'curation' && @resource.process_date.curation_end.blank?
    return if update_dates.empty?

    @resource.process_date.update(update_dates)
    id_dates = update_dates.delete_if { |k, _v| @resource.identifier.process_date.send(k).present? }
    @resource.identifier.process_date.update(id_dates) unless id_dates.empty?
  end

  def process_resource
    return if @resource.skip_datacite_update

    submit_to_datacite
    process_payment
    copy_to_zenodo if @activity.published?
    @resource.submit_to_solr
    @resource.update(hold_for_peer_review: false, peer_review_end_date: nil)
  end

  def process_payment
    return unless @activity.ready_for_payment?

    if @resource.identifier&.user_must_pay?
      submit_to_stripe
    else
      @resource.identifier&.record_payment
    end
    # after first publication, the dataset will be switched to new payment system
    return unless @resource.identifier.old_payment_system

    @resource.identifier.update(old_payment_system: false, last_invoiced_file_size: @resource.total_file_size)
  end

  def submit_to_datacite
    return unless @activity.should_update_doi?

    DataciteService.new(resource).submit
  end

  def submit_to_stripe
    return unless @activity.ready_for_payment?

    inv = Stash::Payments::Invoicer.new(resource: @resource, curator: user)
    if @resource.identifier.payment_type == 'stripe' && @activity.previously_published?
      inv.check_new_overages(@resource.identifier.previous_invoiced_file_size)
    else
      inv.charge_user_via_invoice
    end
  end

  def update_publication_flags
    return unless @activity.can_update_pub_state?(@status)

    case @status
    when 'withdrawn'
      @resource.update_columns(meta_view: false, file_view: false)
    when 'embargoed'
      @resource.update_columns(meta_view: true, file_view: false)
    when 'published'
      @resource.update_columns(meta_view: true, file_view: true)
    end

    return unless @activity.published?

    # find out if there were no file changes since last publication and reset file_view, if so.
    changed = false
    @resource.previous_resources(include_self: true).each do |res|
      break if res.id != @resource.id && res&.last_curation_activity&.status == 'published' # break once reached previous published

      next unless res.files_changed?(association: 'data_files')

      changed = true
      break
    end

    # if nothing changed between previous published and this, don't view same files again
    @resource.update_column(:file_view, false) unless changed
    @resource.update_column(:file_view, false) unless @resource.current_file_uploads.present?
  end

  def update_pub_state
    return if @resource.identifier.pub_state.in?(%w[published embargoed]) && !@activity.can_update_pub_state?(status)

    PubStateService.new(@resource.identifier).update_for_ca_status(@status)
  end

  def update_salesforce_metadata
    @resource.update_salesforce_metadata
    true # ensure return not interrupted
  end

end
