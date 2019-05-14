require_dependency 'stash_engine/application_controller'

module StashEngine
  class SubmissionQueueController < ApplicationController

    include SharedSecurityController
    # include StashEngine::Concerns::Sortable

    before_action :require_admin

    def index
      @queue_rows = RepoQueueState.latest_per_resource.where.not(state: 'completed').order(:hostname, :updated_at)
    end
  end
end