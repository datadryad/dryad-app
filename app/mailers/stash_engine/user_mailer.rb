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
           subject: "#{rails_env}Dryad Submission \"#{@title}\"")

      update_activities(resource: resource, message: 'Status change', status: status)
    end

    # Called from CurationActivity when the status is withdrawn by the system user
    def user_journal_withdrawn(resource, status)
      return unless status == 'withdrawn'

      # Don't send if this was an abandoned dataset
      removed_files_note = 'remove_abandoned_datasets CRON - removing data files from abandoned dataset'
      return if resource.curation_activities&.map(&:note)&.include?(removed_files_note)

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           bcc: @resource&.tenant&.campus_contacts,
           template_name: 'withdrawn_by_journal',
           subject: "#{rails_env}Dryad Submission \"#{@title}\"")

      update_activities(resource: resource, message: 'Withdrawal by journal', status: status)
    end

    # Called from CurationActivity when the status is published or embargoed
    def journal_published_notice(resource, status)
      return unless %w[published embargoed].include?(status)
      return unless APP_CONFIG['send_journal_published_notices']

      assign_variables(resource)
      return unless @resource&.identifier&.journal&.notify_contacts&.present?

      mail(to: @resource&.identifier&.journal&.notify_contacts,
           subject: "#{rails_env}Dryad Submission: \"#{@title}\"")

      update_activities(resource: resource, message: "Status #{status}", status: status, journal: true)
    end

    # Called from CurationActivity when the status is peer_review
    def journal_review_notice(resource, status)
      return unless status == 'peer_review'
      return unless APP_CONFIG['send_journal_published_notices']

      assign_variables(resource)
      return unless @resource&.identifier&.journal&.review_contacts&.present?

      mail(to: @resource&.identifier&.journal&.review_contacts,
           subject: "#{rails_env}Dryad Submission: \"#{@title}\"")

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
           subject: "#{rails_env}Dryad Submission \"#{@resource.title.strip_tags}\"")
    end

    def check_email(email_token)
      return unless email_token.user&.email&.present?

      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @user_name = user_name(email_token.user)
      @token = email_token.token
      mail(to: user_email(email_token.user), subject: "#{rails_env}Your Dryad account code")
    end

    def check_tenant_email(email_token)
      return if email_token.tenant&.authentication&.email_domain.blank?
      return unless email_token.user&.email&.end_with?(email_token.tenant.authentication.email_domain)

      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @user_name = user_name(email_token.user)
      @tenant_name = email_token.tenant&.long_name
      @token = email_token.token
      mail(to: user_email(email_token.user), subject: "#{rails_env}Your Dryad account code")
    end

    def invite_author(edit_code)
      return unless edit_code.author.author_email.present? && edit_code&.edit_code&.present?

      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @user_name = user_name(edit_code.author)
      @resource = edit_code.author.resource
      @role = edit_code.role
      @url = "#{ROOT_URL}#{Rails.application.routes.url_helpers.accept_invite_path(edit_code: edit_code.edit_code)}"
      mail(to: user_email(edit_code.author), subject: "#{rails_env}Invitation to edit submission \"#{@resource.title.strip_tags}\"")
    end

    def invite_user(user, role)
      return unless user.email&.present? && role.role&.present?

      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @user_name = user_name(user)
      @resource = role.role_object
      @role = role.role
      mail(to: user_email(user), subject: "#{rails_env}Invitation to edit submission \"#{@resource.title.strip_tags}\"")
    end

    # Called from the StashEngine::Repository
    def error_report(resource, error)
      logger.warn("Unable to report update error #{error}; nil resource") unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      @backtrace = error.full_message
      mail(to: @submission_error_emails, bcc: @bcc_emails,
           subject: "#{rails_env}Submitting dataset \"#{@title}\" (doi:#{@resource.identifier_value}) failed")
    end

    def general_error(resource, error_text)
      logger.warn("Unable to report update error #{error_text}; nil resource") unless resource.present?
      @zenodo_error_emails = APP_CONFIG['zenodo_error_email']
      return unless resource.present? && @zenodo_error_emails.present?

      @resource = resource

      @error_text = error_text
      mail(to: @zenodo_error_emails,
           subject: "#{rails_env}General error \"#{@resource.title.strip_tags}\" (doi:#{@resource.identifier_value})")
    end

    def file_validation_error(file)
      logger.warn('Unable to validate file checksum; nil file') unless file.present?
      @zenodo_error_emails = APP_CONFIG['zenodo_error_email']
      return unless file.present? && @zenodo_error_emails.present?

      @file = file
      mail(to: @zenodo_error_emails,
           subject: "#{rails_env}File checksum validation error")
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
           subject: "#{rails_env}REMINDER: Dryad Submission \"#{@title}\"")

      # activity updated by rake task
      # update_activities(resource: resource, message: 'In progress reminder', status: 'in_progress')
    end

    def peer_review_reminder(resource)
      logger.warn('Unable to send peer_review_reminder; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad Submission \"#{@title}\"")

      # activity updated by rake task
      # update_activities(resource: resource, message: 'Peer review reminder', status: 'peer_review')
    end

    def peer_review_payment_needed(resource)
      logger.warn('Unable to send peer_review_payment_needed; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      @costs_url = Rails.application.routes.url_helpers.costs_url
      @submission_url = Rails.application.routes.url_helpers.metadata_entry_pages_find_or_create_url(resource_id: resource.id)
      mail(to: user_email(@user),
           subject: "#{rails_env}Dryad Submission \"#{@resource.title}\"")
    end

    def peer_review_pub_linked(resource)
      logger.warn('Unable to send peer_review_pub_linked; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}Dryad Submission \"#{@title}\"")
    end

    def doi_invitation(resource)
      logger.warn('Unable to send doi_invitation; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}Connect your data to your research on Dryad!")

      # activity updated by rake task
      # update_activities(resource: resource, message: 'DOI linking reminder', status: resource.current_curation_status)
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

      bc_email = Rails.env.include?('production') ? @helpdesk_email : nil
      mail(to: user_email(@user), bcc: bc_email,
           subject: "#{rails_env}Related work updated for \"#{@title}\"")
    end

    def chase_action_required1(resource)
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}Action required: Dryad data submission (#{resource&.identifier})")
    end
  end
end
