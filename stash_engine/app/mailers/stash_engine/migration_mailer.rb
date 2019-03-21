module StashEngine

  class MigrationMailer < ApplicationMailer

    # Send the user an email with a link that will let them migrate their datasets
    # from the old dryad system to this Stash based system
    def migration_email
      return false unless current_user.present?
      @email = current_user.old_dryad_email
      @code = current_user.migration_token
      @url = auth_migrate_code_url
      mail(to: @email, subject: 'Dryad Dataset Migration')
    end

  end

end
