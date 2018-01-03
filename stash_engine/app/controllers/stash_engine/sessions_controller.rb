require_dependency 'stash_engine/application_controller'

module StashEngine
  class SessionsController < ApplicationController # rubocop:disable Metrics/ClassLength
    skip_before_action :verify_authenticity_token, only: %i[callback developer_callback orcid_callback]
    before_action :callback_basics, only: %i[callback developer_callback]
    before_action :orcid_shenanigans, only: [:orcid_callback] # do not go to action if it's just a metadata set, not a login

    # this is the place omniauth calls back for shibboleth/google logins
    def callback
      return unless passes_whitelist?
      session[:user_id] = User.from_omniauth(@auth_hash, current_tenant.tenant_id, unmangle_orcid).id
      redirect_to dashboard_path
    end

    def developer_callback
      return if check_developer_orcid!
      check_developer_login!
      return unless passes_whitelist?
      session[:user_id] = User.from_omniauth(@auth_hash, current_tenant.tenant_id, unmangle_orcid).id
      redirect_to dashboard_path
    end

    # takes the orcid logins (which can come from a login or from a metadata entry page), origin=login is main login page
    # the metadata page
    def orcid_callback
      orcid_choose_tenant_or_login!
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
        redirect_to t.omniauth_login_path(orcid: params[:orcid])
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def callback_basics
      @auth_hash = request.env['omniauth.auth']
      reset_session
      head(:forbidden) unless auth_hash_good
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

    # if only orcid filled in then act like it's an orcid login.  Either log in or redirect to choose tenant
    # rubocop:disable Metrics/AbcSize
    def check_developer_orcid!
      return false unless params[:name].blank? && params[:email].blank? && params[:test_domain].blank? && !params[:orcid].blank?
      @orcid = params[:orcid]
      orcid_choose_tenant_or_login!
      true
    end
    # rubocop:enable Metrics/AbcSize

    def passes_whitelist?
      return true if current_tenant.whitelisted?(@auth_hash.info.email)
      redirect_to root_path, flash: { alert: 'You were not authorized to log in' } unless current_tenant.whitelisted?(@auth_hash.info.email)
      false
    end

    # using one controller for multiple orcid login actions (set metadata, log in, orcid_invite so decide which it is before controller)
    def orcid_shenanigans
      @auth_hash = request.env['omniauth.auth']
      @params = request.env['omniauth.params']
      if @params['origin'] == 'metadata'
        metadata_callback
      elsif @params['invitation'] && @params['identifier_id']
        orcid_invitation
      end
      setup_orcid
    end

    def setup_orcid
      @orcid = @auth_hash.uid
      return true if @orcid
      head(:forbidden)
    end

    def orcid_choose_tenant_or_login!
      @users = User.where(orcid: @orcid)

      case @users.count
      when 1
        login_from_orcid
      else
        # either none or multiple users with one ORCID reset those duplicates and make them validate their tenant again
        @users.each { |u| u.update_column(:orcid, nil) } # reset them since there should be only one and make them validate again
        render :choose_sso
      end
    end

    def login_from_orcid
      user = @users.first
      session[:user_id] = user.id
      tenant = Tenant.find(user.tenant_id)
      redirect_to tenant.full_url(dashboard_path)
    end

    # every different login method has different ways of persisting state
    # shibboleth has you make it part of the callback URL you give it (so it shows as one of the normal params in the callback here)
    # omniauth claims to preserve it for certain login types (developer/facebook) in the request.env['omniauth.params']
    # google's oauth2 only passes along things in their special 'state' parameter which then has to have things CGI encoded within it.
    # rubocop:disable Metrics/AbcSize
    def unmangle_orcid
      return request.env['omniauth.params'][:orcid] if request.env['omniauth.params'][:orcid]
      return params[:orcid] if params[:orcid]
      return Rack::Utils.parse_nested_query(params[:state])['orcid'] if params[:state]
      nil
    end
    # rubocop:enable Metrics/AbcSize

    # this gets called from metadata entry form and is for adding an author, not for logging in.
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def metadata_callback
      params = request.env['omniauth.params']
      author = StashEngine::Author.create(
        resource_id: params['resource_id'],
        author_first_name: @auth_hash.info.first_name,
        author_last_name: @auth_hash.info.last_name,
        author_email: current_user.email,
        author_orcid: @auth_hash.uid
      )
      author.affiliation_by_name(current_tenant.short_name)
      current_user.update(orcid: @auth_hash.uid)
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: @params['resource_id'])
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # this is for orcid invitations to add co-authors
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def orcid_invitation
      invitations = OrcidInvitation.where(identifier_id: @params['identifier_id']).where(secret: @params['invitation'])
      identifier = Identifier.find(@params['identifier_id'])
      if invitations.empty?
        redirect_to stash_url_helpers.show_path(identifier.to_s)
        return
      end
      invitation = invitations.first
      if invitation.accepted_at
        redirect_to stash_url_helpers.show_path(identifier.to_s), flash: { info: "You've already added your ORCID to this dataset" }
        return
      end
      update_author_orcid(invitation)
      update_identifier_metadata(invitation)
      redirect_to stash_url_helpers.show_path(identifier.to_s), flash: { info: "Your ORCID #{@auth_hash.uid} has been added for this dataset." }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def update_author_orcid(invitation)
      invitation.update(orcid: @auth_hash['uid'], accepted_at: Time.new)
      last_submitted_resource = invitation.resource
      resources = invitation.identifier.resources.where(['id >= ?', last_submitted_resource.id])
      # updates all orcids for last submitted resource and resources after, even in-progress, error ... whatever
      resources.each do |resource|
        authors = resource.authors.where(author_email: invitation.email)
        authors.update_all(author_orcid: @auth_hash['uid'])
      end
    end

    def update_identifier_metadata(invitation)
      repo = StashEngine.repository
      job = repo.create_submission_job(resource_id: invitation.resource.id)
      job.update_identifier_metadata!
    end
  end
end
