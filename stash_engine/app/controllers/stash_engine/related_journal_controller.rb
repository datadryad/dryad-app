require_dependency 'stash_engine/application_controller'

module StashEngine
  # rubocop:disable Metrics/ClassLength
  class AdminDatasetsController < ApplicationController

    def show
      respond_to do |format|
        format.js
      end
    end

  end
end