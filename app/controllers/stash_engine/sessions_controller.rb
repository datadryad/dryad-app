require_dependency 'stash_engine/application_controller'

module StashEngine
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:callback]

    # this is the place omniauth calls back when logging in
    def callback
      @auth_hash = request.env['omniauth.auth']
      reset_session
      return head(:forbidden) unless auth_hash_good

      if @auth_hash[:provider] == 'developer'
        session[:test_domain] = @auth_hash['info']['test_domain']
        @auth_hash[:uid] = mangle_uid_with_tenant(@auth_hash[:uid], current_tenant.tenant_id)
      end
      session[:user_id] = nil
      user = User.from_omniauth(@auth_hash, current_tenant.tenant_id)
      session[:user_id] = user.id
      redirect_to dashboard_path
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

    #get uid and mangle it with the tenant_id and return it, this is for the developer login to make unique per tenant
    def mangle_uid_with_tenant(uid, tenant_id)
      sp = uid.split('@')
      sp.push('bad-email-domain.com') if sp.length == 1
      sp = ['bad', 'bad-email-domain.com'] if sp.blank? || sp.length > 2
      "#{sp.first}-#{tenant_id}@#{sp.last}"
    end
  end
end
