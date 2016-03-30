require_dependency "stash_engine/application_controller"

module StashEngine
  class LandingController < ApplicationController
    def show
      @identifiers = Identifier.where(identifier: params[:id])
      render 'not_available' and return if @identifiers.count < 1
      @resource_id = @identifiers.first.resource_id
    end

  end
end
