# rubocop:disable Style/MixinUsage
# this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
# to output digital storage sizes
#
include StashEngine::ApplicationHelper
# rubocop:enable Style/MixinUsage

module StashEngine
  class ResourceMailer < ApplicationMailer

    # Called from CurationActivity when the status is queued, peer_review, published, embargoed or withdrawn
    def status_change(resource, status)
      return unless %w[queued peer_review published embargoed withdrawn].include?(status)

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      @feedback_url = feedback_url(m: 5, l: status)
      mail(to: user_email(@user),
           bcc: @resource&.tenant&.campus_contacts,
           template_name: status,
           subject: "#{rails_env}Dryad Submission \"#{@title}\"")

      update_activities(resource: resource, message: 'Status change', status: status)
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

    def in_progress_delete_notification(resource)
      logger.warn('Unable to send in_progress_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      template_name = 'in_progress_reminder'
      template_name = 'published_in_progress_reminder' if resource.previously_published?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"",
           template_name: template_name)
    end

    def peer_review_delete_notification(resource)
      logger.warn('Unable to send peer_review_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"")
    end

    def peer_review_payment_needed(resource)
      logger.warn('Unable to send peer_review_payment_needed; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      @invoice = resource&.payment&.invoice_id&.present?
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

    # def payment_needed(resource)
    #   logger.warn('Unable to send peer_review_payment_needed; nil resource') unless resource.present?
    #   return unless resource.present?
    #
    #   assign_variables(resource)
    #   return unless @user.present? && user_email(@user).present?
    #
    #   @costs_url = Rails.application.routes.url_helpers.costs_url
    #   @submission_url = Rails.application.routes.url_helpers.metadata_entry_pages_find_or_create_url(resource_id: resource.id)
    #   mail(to: user_email(@user),
    #        subject: "#{rails_env}Dryad Submission \"#{@resource.title}\"")
    # end

    def awaiting_payment_delete_notification(resource)
      logger.warn('Unable to send awaiting_payment_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      @invoice = resource&.payment&.invoice_id&.present?
      @costs_url = Rails.application.routes.url_helpers.costs_url
      @submission_url = Rails.application.routes.url_helpers.metadata_entry_pages_find_or_create_url(resource_id: resource.id)

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"")
    end

    def chase_action_required1(resource)
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}Action required: Dryad data submission (#{resource&.identifier})")
    end

    def action_required_delete_notification(resource)
      logger.warn('Unable to send action_required_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"",
           template_name: 'chase_action_required1')
    end

    def send_set_to_withdrawn_notification(resource)
      logger.warn('Unable to send set_to_withdrawn_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}NOTIFICATION: Dryad submission set to withdrawn \"#{@title}\"")
    end

    def send_final_withdrawn_notification(resource)
      logger.warn('Unable to send send_final_withdrawn_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}FINAL NOTIFICATION: Dryad submission will be deleted \"#{@title}\"")
    end

    def delete_notification(resource)
      logger.warn('Unable to send delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}DELETE NOTIFICATION: Dryad submission was deleted \"#{@title}\"")
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

    def related_work_updated(resource)
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      bc_email = Rails.env.include?('production') ? @helpdesk_email : nil
      mail(to: user_email(@user), bcc: bc_email,
           subject: "#{rails_env}Related work updated for \"#{@title}\"")
    end

    def ld_submission(resource)
      @resource = resource
      contact = PayersService.new(resource.identifier.payer).limits_sponsor
      email = contact.payment_configuration&.ldf_limit_notification
      unless email.present?
        logger.warn("No contact to send ld_submission email for resource: #{@resource.id}")
        return
      end

      assign_variables(resource)
      @partner_name = contact.has_attribute?(:name) ? contact.name : contact.long_name

      mail(
        to: email,
        bcc: 'partnerships@datadryad.org',
        subject: "#{rails_env}Notification of Large Data submission to Dryad"
      )
    end

    def ld_publication(resource)
      @resource = resource
      contact = PayersService.new(resource.identifier.payer).limits_sponsor
      email = contact.payment_configuration&.ldf_limit_notification
      unless email.present?
        logger.warn("No contact to send ld_publication email for resource: #{@resource.id}")
        return
      end

      assign_variables(resource)
      tier = ResourceFeeCalculatorService.new(resource).storage_fee_tier
      @storage_fee = tier[:price]
      @partner_name = contact.has_attribute?(:name) ? contact.name : contact.long_name

      mail(
        to: email,
        bcc: 'partnerships@datadryad.org',
        subject: "#{rails_env}Notification of Large Data publication to Dryad"
      )
    end
  end
end
