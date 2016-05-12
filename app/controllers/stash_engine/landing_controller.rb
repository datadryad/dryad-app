require_dependency 'stash_engine/application_controller'

module StashEngine
  class LandingController < ApplicationController
    def show
      render('not_available') && return if params[:id].blank?
      @type, @id = params[:id].split(':', 2)
      @identifiers = Identifier.where(identifier_type: @type).where(identifier: @id)
      render('not_available') && return if @identifiers.count < 1
      @resource_id = @identifiers.first.resource_id
      @resource = Resource.find(@resource_id)
    end
  end
end
