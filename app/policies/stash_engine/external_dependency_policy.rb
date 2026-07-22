module StashEngine
  class ExternalDependencyPolicy < ApplicationPolicy

    def show?
      @user.superuser?
    end

    def auth_failures?
      @user.superuser?
    end

  end
end
