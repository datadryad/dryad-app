require_dependency 'stash_engine/application_controller'

module StashEngine
  class LandingController < ApplicationController
    include StashDatacite::LandingMixin # instead of being hard coded, this should rely on configuration

    def show
      render('not_available') && return if params[:id].blank?
      @type, @id = params[:id].split(':', 2)
      @identifiers = Identifier.where(identifier_type: @type).where(identifier: @id)
      render('not_available') && return if @identifiers.count < 1
      @id = @identifiers.first
      @resource = @id.last_submitted_version
      render('not_available') && return if @resource.blank?
      @resource_id = @resource.id
      @resource.increment_views
      setup_show_variables(@resource_id) #sets up the specific metadata view variables from <meta_engine>::LandingMixin
    end
  end
end
