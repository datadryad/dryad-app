module StashEngine
  class AdminDatasetsPolicy < ApplicationPolicy

    def index?
      @user.min_admin?
    end

    def note_popup?
      @user.min_admin?
    end

    def data_popup?
      @user.min_app_admin?
    end

    def edit_submitter?
      @user.superuser?
    end

    def create_salesforce_case?
      @user.min_app_admin?
    end

    def waiver_add?
      @user.superuser?
    end

    def notification_date?
      @user.superuser?
    end
  end
end
