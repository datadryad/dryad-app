require_dependency 'stash_engine/application_controller'

module StashEngine
  class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: %i[callback developer_callback orcid_callback]
    before_action :callback_basics, only: %i[callback developer_callback]
    before_action :orcid_shenanigans, only: [:orcid_callback] # do not go to action if it's just a metadata set, not a login

    # this is the place omniauth calls back when logging in
    def callback
      return unless passes_whitelist?
      session[:user_id] = User.from_omniauth(@auth_hash, current_tenant.tenant_id, request.env['omniauth.params']['orcid']).id
      redirect_to dashboard_path
    end

    def developer_callback
      # this has orcid: request.env['omniauth.params']['orcid']
      check_developer_login!
      return unless passes_whitelist?
      session[:user_id] = User.from_omniauth(@auth_hash, current_tenant.tenant_id, request.env['omniauth.params']['orcid']).id
      redirect_to dashboard_path
    end

    # takes the orcid logins (which can come from a login or from a metadata entry page), origin=login is main login page
    # the metadata page
    def orcid_callback
      # redirect_to choose_sso_path(orcid: @auth_hash.uid)
      params[:orcid] = @auth_hash.uid
      render :choose_sso
    end

    # destroy the session (ie, log out)
    def destroy
      test_domain = session[:test_domain]
      reset_session
      clear_user
      session[:test_domain] = test_domain
      redirect_to root_path
    end

    def choose_login; end

    # rubocop:disable Metrics/AbcSize
    def choose_sso
      return if params[:tenant_id].blank?
      if params[:tenant_id] == 'developer'
        redirect_to "/stash/auth/developer?#{{ orcid: params[:orcid] }.to_param}"
      else
        t = StashEngine::Tenant.find(params[:tenant_id])
        redirect_to t.omniauth_login_path #(orcid: params[:orcid])
      end
    end

    private

    def callback_basics
      @auth_hash = request.env['omniauth.auth']
      reset_session
      head(:forbidden) unless auth_hash_good
      false
    end

    def set_session
      session.merge!(email:    @auth_hash['info']['email'],
                     name:     @auth_hash['info']['name'],
                     provider: @auth_hash['provider'])
      session[:test_domain] = @auth_hash['info']['test_domain'] if session[:provider] == 'developer'
    end

    def auth_hash_good
      @auth_hash && @auth_hash['info'] && @auth_hash['info']['email'] && @auth_hash['uid']
    end

    # get uid and mangle it with the tenant_id and return it, this is for the developer login to make unique per tenant
    def mangle_uid_with_tenant(uid, tenant_id)
      sp = uid.split('@')
      sp.push('bad-email-domain.com') if sp.length == 1
      sp = ['bad', 'bad-email-domain.com'] if sp.blank? || sp.length > 2
      "#{sp.first}-#{tenant_id}@#{sp.last}"
    end

    def check_developer_login!
      return unless @auth_hash[:provider] == 'developer'
      session[:test_domain] = @auth_hash['info']['test_domain']
      @auth_hash[:uid] = mangle_uid_with_tenant(@auth_hash[:uid], current_tenant.tenant_id)
    end

    def passes_whitelist?
      return true if current_tenant.whitelisted?(@auth_hash.info.email)
      redirect_to root_path, flash: { alert: 'You were not authorized to log in' } unless current_tenant.whitelisted?(@auth_hash.info.email)
      false
    end

    # we are using one controller for multiple orcid login actions (set metadata, log in, so decide which it is before running controller)
    def orcid_shenanigans
      @auth_hash = request.env['omniauth.auth']
      @params = request.env['omniauth.params']
      if @params['origin'] == 'metadata'
        metadata_callback
        return false
      end
      reset_session
    end

    # this gets called from metadata entry form and is for adding an author, not for logging in.
    def metadata_callback
      params = request.env['omniauth.params']
      StashEngine::Author.create(
        resource_id: params['resource_id'],
        author_first_name: @auth_hash.info.first_name,
        author_last_name: @auth_hash.info.last_name,
        author_orcid: @auth_hash.uid
      )
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: @params['resource_id'])
    end
  end
end
