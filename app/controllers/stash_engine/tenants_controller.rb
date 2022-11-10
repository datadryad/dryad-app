require 'stash_engine/application_controller'

module StashEngine
  class TenantsController < ApplicationController
    # GET /tenants
    def index
      @tenants = Tenant.all
    end
  end
end
