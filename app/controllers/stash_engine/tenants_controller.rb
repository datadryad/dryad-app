require_dependency "stash_engine/application_controller"

module StashEngine
  class TenantsController < ApplicationController
    before_action :set_tenant, only: [:show, :edit, :update, :destroy]

    # GET /tenants
    def index
      @tenants = Tenant.all
    end

    # GET /tenants/1
    def show
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_tenant
        @tenant = Tenant.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def tenant_params
        params[:tenant]
      end
  end
end
