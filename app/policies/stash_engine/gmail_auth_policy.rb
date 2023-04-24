module StashEngine
  class GmailAuthPolicy < ApplicationPolicy
    attr_reader :user

    def initialize(user, _record)
      super
      @user = user
    end

    def index?
      user.superuser?
    end
  end
end
