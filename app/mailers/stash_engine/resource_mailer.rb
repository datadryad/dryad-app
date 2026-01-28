# rubocop:disable Style/MixinUsage
# this drops in a couple methods and makes "def filesize(bytes, decimal_points = 2)" available
# to output digital storage sizes
#
include StashEngine::ApplicationHelper
# rubocop:enable Style/MixinUsage

module StashEngine
  # Mails users about submissions
  class ResourceMailer < ApplicationMailer

    def in_progress_delete_notification(resource)
      logger.warn('Unable to send in_progress_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      template_name = 'in_progress_reminder'
      template_name = 'published_in_progress_reminder' if resource.previously_published?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"",
           template_path: 'stash_engine/user_mailer',
           template_name: template_name)
    end

    def peer_review_delete_notification(resource)
      logger.warn('Unable to send peer_review_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"",
           template_path: 'stash_engine/user_mailer',
           template_name: 'peer_review_reminder')
    end

    def awaiting_payment_delete_notification(resource)
      logger.warn('Unable to send awaiting_payment_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      @invoice = resource&.payment&.invoice_id&.present?
      @costs_url = Rails.application.routes.url_helpers.costs_url
      @submission_url = Rails.application.routes.url_helpers.metadata_entry_pages_find_or_create_url(resource_id: resource.id)

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"",
           template_path: 'stash_engine/user_mailer',
           template_name: 'awaiting_payment_reminder')
    end

    def action_required_delete_notification(resource)
      logger.warn('Unable to send action_required_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@title}\"",
           template_path: 'stash_engine/user_mailer',
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

    def ld_submission(resource)
      @resource = resource
      if @resource.tenant&.campus_contacts&.blank?
        logger.warn("No campus_contact to send ld_submission email for resource: #{@resource.id}")
        return
      end

      assign_variables(resource)
      @partner_name = resource.tenant.short_name

      mail(
        to: @resource.tenant&.campus_contacts,
        bcc: 'partnerships@datadryad.org',
        subject: "#{rails_env}Notification of Large Data submission to Dryad"
      )
    end

    def ld_publication(resource)
      @resource = resource
      if @resource.tenant&.campus_contacts&.blank?
        logger.warn("No campus_contact to send ld_publication email for resource: #{@resource.id}")
        return
      end

      assign_variables(resource)
      tier = ResourceFeeCalculatorService.new(resource).storage_fee_tier
      @storage_fee = tier[:price]
      @partner_name = resource.tenant.short_name

      mail(
        to: @resource.tenant&.campus_contacts,
        bcc: 'partnerships@datadryad.org',
        subject: "#{rails_env}Notification of Large Data publication to Dryad"
      )
    end
  end
end
