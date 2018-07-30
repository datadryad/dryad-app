module StashEngine
  class MigrationMailer < ApplicationMailer
    default from: 'help@datadryad.org'
    def migration_email(user)
      @email = user[:email]
      @code = user[:code]
      @url = "test test"
      mail(to: @email)
    end
  end
end
