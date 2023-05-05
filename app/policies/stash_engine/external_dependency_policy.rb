module StashEngine
  class ExternalDependencyPolicy < ApplicationPolicy

    def show?
      @user.superuser?
    end

  end
end
