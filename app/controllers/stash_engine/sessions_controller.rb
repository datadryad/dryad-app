require_dependency 'stash_engine/application_controller'

module StashEngine
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    # this is the place omniauth calls back when logging in
    def callback
      @auth_hash = request.env['omniauth.auth']
      reset_session
      return head(:forbidden) unless auth_hash_good

      session[:test_domain] = @auth_hash['info']['test_domain'] if @auth_hash[:provider] == 'developer'
      session[:user_id] = nil
      user = User.from_omniauth(@auth_hash, current_tenant.tenant_id)
      session[:user_id] = user.id
      if user.resources.empty?
        redirect_to get_started_path
      else
        redirect_to dashboard_path
      end
    end

    # destroy the session (ie, log out)
    def destroy
      test_domain = session[:test_domain]
      reset_session
      clear_user
      session[:test_domain] = test_domain
      redirect_to root_path
    end

    private

    def set_session
      session.merge!(email:    @auth_hash['info']['email'],
                     name:     @auth_hash['info']['name'],
                     provider: @auth_hash['provider'])
      session[:test_domain] = @auth_hash['info']['test_domain'] if session[:provider] == 'developer'
    end

    def auth_hash_good
      @auth_hash && @auth_hash['info'] && @auth_hash['info']['email'] && @auth_hash['uid']
    end
  end
end
