module StashEngine
  class UserAccountController < ApplicationController
    before_action :require_user_login

    def index
      @target_page = stash_url_helpers.my_account_path
    end

    def edit
      return render(nothing: true, status: :unauthorized) unless current_user

      current_user.update(email: params[:email], first_name: params[:first_name], last_name: params[:last_name])
      respond_to(&:js)
    end

    def api_application
      render :edit and return if current_user.api_application

      Doorkeeper::Application.create(name: current_user.name, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', owner_type: 'StashEngine::User',
                                     owner_id: current_user.id)
      current_user.reload
      api_token
    end

    def api_token
      render :edit and return unless current_user.api_application

      Doorkeeper::AccessToken.find_or_create_for(application: current_user.api_application, resource_owner: current_user.id, scopes: '',
                                                 expires_in: 36_000)

      render :edit
    end
  end
end
