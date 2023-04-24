module StashEngine
  class ZenodoCopyPolicy < ApplicationPolicy

    def index?
      @user.superuser?
    end

    def item_details?
      @user.superuser?
    end

    def identifier_details?
      @user.superuser?
    end

    def resubmit_job?
      @user.superuser?
    end

    def set_errored?
      @user.superuser?
    end
  end
end
