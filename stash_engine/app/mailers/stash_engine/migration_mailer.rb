module StashEngine

  class MigrationMailer < ApplicationMailer

    # Send the user an email with a link that will let them migrate their datasets
    # from the old dryad system to this Stash based system
    def migration_email(user)
      return false unless user.present?
      @email = user.old_dryad_email
      @code = user.migration_token
      @url = auth_migrate_code_url
      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      mail(to: @email, subject: 'Dryad Dataset Migration')
    end

  end

end
