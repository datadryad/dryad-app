module StashEngine
  class JournalMailer < ApplicationMailer

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
  end
end
