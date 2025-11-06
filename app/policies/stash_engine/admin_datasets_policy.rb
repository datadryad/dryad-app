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
      @user.min_manager?
    end

    def create_issue?
      @user.min_app_admin?
    end

    def create_salesforce_case?
      @user.min_app_admin?
    end

    def waiver_add?
      @user.min_manager?
    end

    def add_concern?
      @user.min_manager?
    end

    def notification_date?
      @user.min_manager?
    end
  end
end
