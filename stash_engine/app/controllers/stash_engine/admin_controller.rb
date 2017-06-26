require_dependency "stash_engine/application_controller"

module StashEngine
  class AdminController < ApplicationController

    def index
      setup_superuser_stats
    end


    private
    def setup_superuser_stats
      @user_count = User.all.count
      @dataset_count = Identifier.all.count
      #7 days
      @users_7days = User.where(['created_at > ?', Time.new - 7.days]).count
      # this works because UI only allows one in progress version of each dataset at a time
      @ds_started_7days = Resource.joins(:current_resource_state).where(stash_engine_resource_states: { resource_state:  %i[in_progress] }).where(['created_at > ?', Time.new - 7.days]).count
      @ds_submitted_7days = Identifier.where(['created_at > ?', Time.new - 7.days]).count
    end
  end
end
