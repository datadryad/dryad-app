require_dependency 'stash_engine/application_controller'

module StashEngine
  class SessionsController < ApplicationController # rubocop:disable Metrics/ClassLength

    before_action :require_login, only: %i[callback]
    skip_before_action :verify_authenticity_token, only: %i[callback orcid_callback] # omniauth takes care of this differently
    before_action :callback_basics, only: %i[callback]
    before_action :orcid_preprocessor, only: [:orcid_callback] # do not go to main action if it's just a metadata set, not a login

    # this is the place omniauth calls back for shibboleth/google logins
    def callback
      current_user.update(tenant_id: params[:tenant_id])
      redirect_to dashboard_path
    end

    # would only get here if the pre-processor decides this is an actual login and not just an orcid validation (by login)
    def orcid_callback
      emails = orcid_api_emails(orcid: @auth_hash[:uid], bearer_token: @auth_hash[:credentials][:token])
      user = User.from_omniauth_orcid(auth_hash: @auth_hash, emails: emails)
      employment = handle_orcid_employments(orcid: @auth_hash[:uid], bearer_token: @auth_hash[:credentials][:token])
      user.update(affiliation_id: employment&.id) unless employment.blank?
      session[:user_id] = user.id
      user.set_migration_token
      if user.tenant_id.present?
        redirect_to dashboard_path
      else
        redirect_to choose_sso_path
      end
    end

    # destroy the session (ie, log out)
    def destroy
      reset_session
      clear_user
      redirect_to root_path
    end

    def choose_login; end

    def choose_sso
      tenants = [OpenStruct.new(id: '', name: '')]
      tenants << StashEngine::Tenant.partner_list.map do |t|
        OpenStruct.new(id: t.tenant_id, name: t.short_name)
      end

      # If no tenants are defined redirect to the no_parter path
      if tenants.empty?
        redirect_to :no_partner, method: :post
      else
        @tenants = tenants.flatten
      end
    end

    # no partner, so set as generic dryad tenant without membership benefits
    def no_partner
      current_user.tenant_id = APP_CONFIG.default_tenant
      current_user.save!
      redirect_to dashboard_path
    end

    # send the user to the tenant's SSO url
    def sso
      tenant = StashEngine::Tenant.find(params[:tenant_id])
      if tenant.present?
        redirect_to tenant.omniauth_login_path(tenant_id: tenant.tenant_id)
      else
        render :choose_sso, alert: 'You must select a partner institution from the list.'
      end
    end

    private

    def callback_basics
      @auth_hash = request.env['omniauth.auth']
      head(:forbidden) unless auth_hash_good
    end

    def set_session
      session.merge!(email:    @auth_hash['info']['email'],
                     name:     @auth_hash['info']['name'],
                     provider: @auth_hash['provider'])
    end

    def auth_hash_good
      @auth_hash && @auth_hash['info'] && @auth_hash['info']['email'] && @auth_hash['uid']
    end

    # using one controller for multiple orcid login actions (set metadata, log in, orcid_invite so decide which it is before controller)
    def orcid_preprocessor
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

    def login_from_orcid
      user = @users.first
      session[:user_id] = user.id
      # tenant = Tenant.find(user.tenant_id) # this was used to redirect to correct tenant, now not needed
      redirect_to dashboard_path
    end

    # get orcid emails as returned by API
    def orcid_api_emails(orcid:, bearer_token:)
      resp = RestClient.get "#{StashEngine.app.orcid.api}/v2.1/#{orcid}/email",
                            'Content-type' => 'application/vnd.orcid+json', 'Authorization' => "Bearer #{bearer_token}"
      my_info = JSON.parse(resp.body)
      my_info['email'].map { |item| (item['email'].blank? ? nil : item['email']) }.compact
    rescue RestClient::Exception => e
      logger.error(e)
      []
    end

    def handle_orcid_employments(orcid:, bearer_token:)
      resp = RestClient.get "#{StashEngine.app.orcid.api}/v2.1/#{orcid}/employments",
                            'Content-type' => 'application/vnd.orcid+json', 'Authorization' => "Bearer #{bearer_token}"
      my_info = JSON.parse(resp.body)
      orgs = my_info['employment-summary'].map { |item| (item['organization'].blank? ? nil : item['organization']) }.compact
      orgs = orgs.map do |org|
        affil = StashDatacite::Affiliation.from_long_name(org['name'])
        affil.save if affil.present?
        affil
      end
      orgs.first
    rescue RestClient::Exception => e
      logger.error(e)
      []
    end

    # every different login method has different ways of persisting state
    # shibboleth has you make it part of the callback URL you give it (so it shows as one of the normal params in the callback here)
    # omniauth claims to preserve it for certain login types (developer/facebook) in the request.env['omniauth.params']
    # google's oauth2 only passes along things in their special 'state' parameter which then has to have things CGI encoded within it.
    def unmangle_orcid
      return request.env['omniauth.params'][:orcid] if request.env['omniauth.params'][:orcid]
      return params[:orcid] if params[:orcid]
      return Rack::Utils.parse_nested_query(params[:state])['orcid'] if params[:state]
      nil
    end

    # this gets called from metadata entry form and is for adding an author, not for logging in.
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

    # this is for orcid invitations to add co-authors
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
      update_identifier_metadata(invitation) # TODO: This needs to be more selective and only update if DS is public or embargoed
      redirect_to stash_url_helpers.show_path(identifier.to_s), flash: { info: "Your ORCID #{@auth_hash.uid} has been added for this dataset." }
    end

    def update_author_orcid(invitation)
      invitation.update(orcid: @auth_hash['uid'], accepted_at: Time.new.utc)
      last_submitted_resource = invitation.resource
      resources = invitation.identifier.resources.where(['id >= ?', last_submitted_resource.id])
      # updates all orcids for last submitted resource and resources after, even in-progress, error ... whatever
      resources.each do |resource|
        authors = resource.authors.where(author_email: invitation.email)
        authors.update_all(author_orcid: @auth_hash['uid'])
      end
    end

    def update_identifier_metadata(invitation)
      id_svc = Stash::Doi::IdGen.make_instance(resource: invitation.resource)
      id_svc.update_identifier_metadata!
    end

  end
end
