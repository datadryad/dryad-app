require_dependency "stash_engine/application_controller"

module StashEngine
  class SessionsController < ApplicationController
    def index
    end

    # this is the place omniauth calls back when logging in
    def callback
      @auth_hash = request.env['omniauth.auth']
      if @auth_hash['info'] && @auth_hash['info']['email'] && @auth_hash['info']['name']
        session[:email], session[:name], session[:provider] =
            @auth_hash['info']['email'], @auth_hash['info']['name'], @auth_hash['provider']
        session[:test_domain] = @auth_hash['info']['test_domain'] if session[:provider] == 'developer'
        #redirect_to dashboard_path
      else
        # redirect_to tenants_path
      end
    end

    # destroy the session (ie, log out)
    def destroy
      reset_session
      redirect_to root_path
    end

  end
end