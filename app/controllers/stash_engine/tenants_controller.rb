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

    # GET /tenants/new
    def new
      @tenant = Tenant.new
    end

    # GET /tenants/1/edit
    def edit
    end

    # POST /tenants
    def create
      @tenant = Tenant.new(tenant_params)

      if @tenant.save
        redirect_to @tenant, notice: 'Tenant was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /tenants/1
    def update
      if @tenant.update(tenant_params)
        redirect_to @tenant, notice: 'Tenant was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /tenants/1
    def destroy
      @tenant.destroy
      redirect_to tenants_url, notice: 'Tenant was successfully destroyed.'
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
