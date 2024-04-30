module StashEngine
  class JournalOrganizationPolicy < ApplicationPolicy

    def load?
      @user.superuser?
    end

  end
end
