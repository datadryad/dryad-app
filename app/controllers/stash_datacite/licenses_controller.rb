require_dependency "stash_datacite/application_controller"

module StashDatacite
  class LicensesController < ApplicationController

    # display details for a license
    def details
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      @rights = @resource.rights
      respond_to do |format|
        format.js
      end
    end
  end
end
