module StashEngine
  class MigrationMailer < ApplicationMailer
    @help = 'help@datadryad.org'
    default from: @help
    def migration_email(user)
      @email = user[:email]
      @code = user[:code]
      @url = user[:url]
      mail(to: @email)
    end
  end
end
