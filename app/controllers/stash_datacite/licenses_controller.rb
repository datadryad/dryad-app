module StashDatacite
  class LicensesController < ApplicationController
    # display details for a license
    def details
      @resource = StashEngine::Resource.find(params[:resource_id])
      @rights = @resource.rights
      respond_to(&:js)
    end
  end
end
