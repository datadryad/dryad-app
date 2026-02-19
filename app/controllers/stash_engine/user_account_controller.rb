module StashEngine
  class UserAccountController < ApplicationController
    before_action :require_user_login, only: %i[edit request_merge]
    before_action :require_login, except: %i[edit request_merge]

    def index
      require_user_login if current_user.proxy_user?
    end

    def edit
      @email = params[:email].squish
      validated = current_user.email&.downcase == @email.downcase
      @existing_user = StashEngine::User.find_by(email: @email)
      # rubocop:disable Style/GuardClause
      if @email.present? && !validated && @existing_user.present?
        if @existing_user.orcid.blank? && @existing_user.resources.empty?
          current_user.merge_user!(other_user: @existing_user, overwrite: false)
          @existing_user.destroy
        else
          render :duplicate_email, formats: :js and return
        end
      end
      # rubocop:enable Style/GuardClause

      session[:target_page] = stash_url_helpers.my_account_path unless validated
      current_user.update(email: @email, first_name: params[:first_name], last_name: params[:last_name], validated: validated)
      respond_to(&:js)
    end

    def request_merge
      existing_user = StashEngine::User.find_by(id: params[:merge])
      StashEngine::UserMailer.merge_request(current_user, existing_user).deliver_now
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

      Doorkeeper::AccessToken.find_or_create_for(application: current_user.api_application, scopes: 'all', expires_in: 36_000)

      render :edit
    end
  end
end
