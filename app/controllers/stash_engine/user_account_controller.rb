module StashEngine
  class UserAccountController < ApplicationController
    before_action :require_user_login

    def index
      session[:origin] = 'account'
    end

    def edit
      return render(nothing: true, status: :unauthorized) unless current_user

      current_user.update(email: params[:email], first_name: params[:first_name], last_name: params[:last_name])
      respond_to(&:js)
    end

  end
end
