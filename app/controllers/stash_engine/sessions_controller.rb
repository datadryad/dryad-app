require_dependency 'stash_engine/application_controller'

module StashEngine
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    def index
    end

    # this is the place omniauth calls back when logging in
    def callback
      @auth_hash = request.env['omniauth.auth']
      reset_session
      if @auth_hash && @auth_hash['info'] && @auth_hash['info']['email'] && @auth_hash['info']['name']
        set_session
        redirect_to dashboard_path
      else
        return head(:forbidden)
      end
    end

    # destroy the session (ie, log out)
    def destroy
      reset_session
      redirect_to root_path
    end

    private

    def set_session
      session.merge!(email:    @auth_hash['info']['email'],
                     name:     @auth_hash['info']['name'],
                     provider: @auth_hash['provider'])
      session[:test_domain] = @auth_hash['info']['test_domain'] if session[:provider] == 'developer'
    end
  end
end
