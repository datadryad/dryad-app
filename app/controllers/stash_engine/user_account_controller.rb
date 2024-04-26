module StashEngine
  class UserAccountController < ApplicationController
    before_action :require_user_login

    def index
      @orcid_link = orcid_link
      @tenants = StashEngine::Tenant.partner_list.map { |t| { id: t.id, name: t.short_name } }
      session[:origin] = 'account'
    end

    def edit
      return render(nothing: true, status: :unauthorized) unless current_user

      current_user.update(email: params[:email], first_name: params[:first_name], last_name: params[:last_name])
      respond_to(&:js)
    end

    def orcid_link
      return "https://sandbox.orcid.org/#{current_user.orcid}" if APP_CONFIG.orcid.site == 'https://sandbox.orcid.org/'

      "https://orcid.org/#{current_user.orcid}"
    end

  end
end
