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
  end
end
