module StashDatacite
  class CreditRolesController < ApplicationController

    # GET /credit_roles
    def index
      render json: StashDatacite::CreditRole.all
    end

  end
end
