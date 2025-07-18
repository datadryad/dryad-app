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
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@resource.title}\"",
           template_path: 'stash_engine/user_mailer',
           template_name: template_name)
    end

    def peer_review_delete_notification(resource)
      logger.warn('Unable to send peer_review_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@resource.title}\"",
           template_path: 'stash_engine/user_mailer',
           template_name: 'peer_review_reminder')
    end

    def action_required_delete_notification(resource)
      logger.warn('Unable to send action_required_delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}REMINDER: Dryad submission \"#{@resource.title}\"",
           template_path: 'stash_engine/user_mailer',
           template_name: 'chase_action_required1')
    end

    def send_set_to_withdrawn_notification(resource)
      logger.warn('Unable to send set_to_withdrawn_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}NOTIFICATION: Dryad submission set to withdrawn \"#{@resource.title}\"")
    end

    def send_final_withdrawn_notification(resource)
      logger.warn('Unable to send send_final_withdrawn_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}FINAL NOTIFICATION: Dryad submission will be deleted \"#{@resource.title}\"")
    end

    def delete_notification(resource)
      logger.warn('Unable to send delete_notification; nil resource') unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      mail(to: user_email(@user),
           subject: "#{rails_env}DELETE NOTIFICATION: Dryad submission was deleted \"#{@resource.title}\"")
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
      @user = resource.owner_author || resource.submitter
      @user_name = user_name(@user)
      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @bcc_emails = APP_CONFIG['submission_bc_emails'] || [@helpdesk_email]
      @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
      @page_error_emails = APP_CONFIG['page_error_email'] || [@helpdesk_email]
    end

    def rails_env
      return "[#{Rails.env}] " unless Rails.env.include?('production')

      ''
    end

    def address_list(addresses)
      addresses = [addresses] unless addresses.respond_to?(:join)
      addresses.flatten.reject(&:blank?).join(',')
    end

  end

end
