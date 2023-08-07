module StashEngine

  # Mails users about submissions
  class UserMailer < ApplicationMailer

    # Called from CurationActivity when the status is submitted, peer_review, published, embargoed or withdrawn
    def status_change(resource, status)
      return unless %w[submitted peer_review published embargoed withdrawn].include?(status)

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      @feedback_url = feedback_url(m: 5, l: status)
      mail(to: user_email(@user),
           bcc: @resource&.tenant&.campus_contacts,
           template_name: status,
           subject: "#{rails_env}Dryad Submission \"#{@resource.title}\"")

      update_activities(resource: resource, message: 'Status change', status: status)
    end

    # Called from CurationActivity when the status is withdrawn by the system user
    def user_journal_withdrawn(resource, status)
      return unless status == 'withdrawn'

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           bcc: @resource&.tenant&.campus_contacts,
           template_name: withdrawn_by_journal,
           subject: "#{rails_env}Dryad Submission \"#{@resource.title}\"")

      update_activities(resource: resource, message: 'Withdrawal by journal', status: status)
    end

    # Called from CurationActivity when the status is published or embargoed
    def journal_published_notice(resource, status)
      return unless %w[published embargoed].include?(status)
      return unless APP_CONFIG['send_journal_published_notices']

      assign_variables(resource)
      return unless @resource&.identifier&.journal&.notify_contacts&.present?

      mail(to: @resource&.identifier&.journal&.notify_contacts,
           subject: "#{rails_env}Dryad Submission: \"#{@resource.title}\"")

      update_activities(resource: resource, message: "Status #{status}", status: status, journal: true)
    end

    # Called from CurationActivity when the status is peer_review
    def journal_review_notice(resource, status)
      return unless status == 'peer_review'
      return unless APP_CONFIG['send_journal_published_notices']

      assign_variables(resource)
      return unless @resource&.identifier&.journal&.review_contacts&.present?

      mail(to: @resource&.identifier&.journal&.review_contacts,
           subject: "#{rails_env}Dryad Submission: \"#{@resource.title}\"")

      update_activities(resource: resource, message: 'Private for peer review', status: status, journal: true)
    end

    # Called from the LandingController when an update happens
    def orcid_invitation(orcid_invite)
      # need to calculate url here because url helpers work erratically in the mailer template itself
      path = Rails.application.routes.url_helpers.show_path(orcid_invite.identifier.to_s, invitation: orcid_invite.secret)
      @url = orcid_invite.landing(path)
      @resource = orcid_invite.resource
      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @user_name = "#{orcid_invite.first_name} #{orcid_invite.last_name}"
      mail(to: orcid_invite.email,
           subject: "#{rails_env}Dryad Submission \"#{@resource.title}\"")
    end

    # Called from the StashEngine::Repository
    def error_report(resource, error)
      logger.warn("Unable to report update error #{error}; nil resource") unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      @backtrace = error.full_message
      mail(to: @submission_error_emails, bcc: @bcc_emails,
           subject: "#{rails_env}Submitting dataset \"#{@resource.title}\" (doi:#{@resource.identifier_value}) failed")
    end

    def feedback_signup(message)
      @message = message
      @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
      mail(to: @submission_error_emails, subject: "#{rails_env}User testing signup")
    end

    def in_progress_reminder(resource)
      logger.warn('Unable to send in_progress_reminder; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad Submission \"#{@resource.title}\"")

      # activity updated by rake task
      # update_activities(resource: resource, message: 'In progress reminder', status: 'in_progress')
    end

    def peer_review_reminder(resource)
      logger.warn('Unable to send peer_review_reminder; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad Submission \"#{@resource.title}\"")

      # activity updated by rake task
      # update_activities(resource: resource, message: 'Peer review reminder', status: 'peer_review')
    end
    end

    def dependency_offline(dependency, message)
      return unless dependency.present?

      @dependency = dependency
      @url = status_dashboard_url
      @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
      @message = message
      mail(to: @submission_error_emails, bcc: @bcc_emails,
           subject: "#{rails_env}dependency offline: #{dependency.name}")
    end

    def zenodo_error(zenodo_copy_obj)
      @zen = zenodo_copy_obj
      logger.warn('Unable to report zenodo error, no zenodo copy object') unless @zen.present?
      return unless @zen.present?

      @zenodo_error_emails = APP_CONFIG['zenodo_error_email'] || [@helpdesk_email]

      mail(to: @zenodo_error_emails,
           subject: "#{rails_env}Failed to update Zenodo for #{@zen.identifier} for event type #{@zen.copy_type}")
    end

    def voided_invoices(voided_identifier_list)
      return unless voided_identifier_list.present?

      @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
      @identifiers = voided_identifier_list
      mail(to: @submission_error_emails,
           subject: "#{rails_env}Voided invoices need to be updated")
    end

    def related_work_updated(resource)
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      bc_email = Rails.env.production? ? @helpdesk_email : nil
      mail(to: user_email(@user), bcc: bc_email,
           subject: "#{rails_env}Related work updated for \"#{resource.title}\"")
    end

    private

    # rubocop:disable Style/NestedTernaryOperator
    def user_email(user)
      user.present? ? (user.respond_to?(:author_email) ? user.author_email : user.email) : nil
    end

    def user_name(user)
      user.present? ? (user.respond_to?(:author_standard_name) ? user.author_standard_name : user.name) : nil
    end
    # rubocop:enable Style/NestedTernaryOperator

    def assign_variables(resource)
      @resource = resource
      @user = resource.owner_author || resource.user
      @user_name = user_name(@user)
      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @bcc_emails = APP_CONFIG['submission_bc_emails'] || [@helpdesk_email]
      @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
      @page_error_emails = APP_CONFIG['page_error_email'] || [@helpdesk_email]
    end

    def update_activities(resource:, message:, status:, journal: false)
      recipient = journal ? 'journal' : 'author'
      note = "#{message} notification sent to #{recipient}"
      StashEngine::CurationActivity.create(resource: resource,
                                           user_id: 0,  # system user
                                           note: note,
                                           status: status)
    end

    def rails_env
      return "[#{Rails.env}] " unless Rails.env == 'production'

      ''
    end

    def address_list(addresses)
      addresses = [addresses] unless addresses.respond_to?(:join)
      addresses.flatten.reject(&:blank?).join(',')
    end

  end

end
