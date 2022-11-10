require 'stash_datacite/application_controller'

module StashDatacite
  class LicensesController < ApplicationController
    # display details for a license
    def details
      @resource = StashEngine::Resource.find(params[:resource_id])
      @rights = @resource.rights
      respond_to do |format|
        format.js
      end
    end
  end
end
