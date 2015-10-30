require_dependency "stash_engine/application_controller"

module StashEngine
  class TestController < ApplicationController
    def index
    end

    def after_login
      @auth_hash = request.env['omniauth.auth']
      if @auth_hash['info'] && @auth_hash['info']['email'] && @auth_hash['info']['name']
        session[:email], session[:name] = @auth_hash['info']['email'], @auth_hash['info']['name']
        redirect_to dashboard_path
      else
        redirect_to tenants_path
      end
    end
  end
end
