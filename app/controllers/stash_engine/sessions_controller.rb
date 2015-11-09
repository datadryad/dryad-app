require_dependency "stash_engine/application_controller"

module StashEngine
  class SessionsController < ApplicationController
    def index
    end

    def callback
      @auth_hash = request.env['omniauth.auth']
      if @auth_hash['info'] && @auth_hash['info']['email'] && @auth_hash['info']['name']
        session[:email], session[:name], session[:provider] =
            @auth_hash['info']['email'], @auth_hash['info']['name'], @auth_hash['provider']
        # redirect_to dashboard_path
      else
        # redirect_to tenants_path
      end
    end
  end
end