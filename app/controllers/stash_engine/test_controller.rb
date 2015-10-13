require_dependency "stash_engine/application_controller"

module StashEngine
  class TestController < ApplicationController
    def index
    end

    def after_login
      @auth_hash = request.env['omniauth.auth']
    end
  end
end
