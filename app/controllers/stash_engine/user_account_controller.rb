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

  end
end
