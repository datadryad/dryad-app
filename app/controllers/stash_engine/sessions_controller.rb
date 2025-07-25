require 'ipaddr'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# rubocop:disable Metrics/ClassLength
module StashEngine
  class SessionsController < ApplicationController

    before_action :bust_cache
    before_action :require_user_login, only: %i[choose_sso no_partner callback sso email_validate]
    skip_before_action :verify_authenticity_token, only: %i[callback orcid_callback] # omniauth takes care of this differently
    before_action :callback_basics, only: %i[callback]
    before_action :orcid_preprocessor, only: [:orcid_callback] # do not go to main action if it's just a metadata set, not a login

    # this is the place omniauth calls back for shibboleth logins
    def callback
      current_user.roles.tenant_roles.delete_all if current_user.tenant_id != params[:tenant_id]
      current_user.update(tenant_id: params[:tenant_id], tenant_auth_date: Time.current)
      do_redirect
    end

    # would only get here if the pre-processor decides this is an actual login and not just an orcid validation (by login)
    def orcid_callback
      emails = orcid_api_emails(orcid: @auth_hash[:uid], bearer_token: @auth_hash[:credentials][:token])
      user = StashEngine::User.from_omniauth_orcid(auth_hash: @auth_hash, emails: emails)
      employment = handle_orcid_employments(orcid: @auth_hash[:uid], bearer_token: @auth_hash[:credentials][:token])
      user.update(affiliation_id: employment&.id) unless employment.blank?
      session[:user_id] = user.id
      if user.tenant_id.present?
        do_redirect
      else
        redirect_to stash_url_helpers.choose_sso_path
      end
    end

    def google_callback
      # Get access tokens from the google server
      auth_info = request.env['omniauth.auth'].credentials

      # Unlike the other callbacks in this controller, we're not going to login a user,
      # we're only going to save the credentials in a file.
      # The Google authentication is currently only used to obtain access to the account
      # that receives metadata emails from journals.

      credentials = { client_id: APP_CONFIG[:google][:gmail_client_id],
                      client_secret: '', # Don't store the secret; it's in our config already
                      token: auth_info.token,
                      refresh_token: auth_info.refresh_token }

      File.write(APP_CONFIG[:google][:token_path], JSON.dump(credentials))

      flash[:notice] = 'Authorized to connect with GMail.'

      redirect_to Rails.application.routes.url_helpers.gmail_auth_path
    end

    # destroy the session (ie, log out)
    def destroy
      reset_session
      clear_user
      redirect_to Rails.application.routes.url_helpers.root_path
    end

    def choose_login; end

    def feedback; end

    def feedback_signup
      if current_user || verify_recaptcha
        message = ''
        params.each do |k, v|
          message = "#{message}#{k}: #{v}\n" if %w[authenticity_token commit controller action g-recaptcha-response].exclude?(k)
        end
        StashEngine::UserMailer.feedback_signup(message).deliver_now
        redirect_to stash_url_helpers.feedback_path, notice: 'Sign up successful. Thank you!'
      else
        redirect_to stash_url_helpers.feedback_path, flash: { alert: 'Please fill in reCAPTCHA' }
      end
    end

    # this only available in non-production environments and only if special environment variable set when starting server
    def test_login
      return render(body: 'unauthorized', status: 401) if Rails.env.include?('prod') || ENV['TEST_LOGIN'].blank?

      @tenants = [OpenStruct.new(id: 'dryad', name: 'Dryad')]
      @tenants << StashEngine::Tenant.partner_list.map do |t|
        OpenStruct.new(id: t.id, name: t.short_name)
      end
      @tenants.flatten!

      return if request.method == 'GET'

      return render(body: 'ORCID must not be blank', status: 403) if params[:orcid].blank?

      existing = User.where(orcid: params[:orcid].strip).first || User.create(orcid: params[:orcid].strip)
      existing.update(first_name: params[:first_name], last_name: params[:last_name], email: params[:email],
                      tenant_id: params[:tenant_id])
      session[:user_id] = existing.id
      redirect_to stash_url_helpers.choose_dashboard_path, status: :found
    end

    def choose_sso
      tenants = StashEngine::Tenant.connect_list.map { |t| { id: t.id, name: t.short_name } }
      # If no tenants are defined redirect to the no_parter path
      if tenants.empty?
        redirect_to :no_partner, method: :post
      else
        @tenants = tenants
      end
      set_default_tenant if current_user.tenant_id.blank?
    end

    # no partner, so set as generic dryad tenant without membership benefits
    def no_partner
      session[:target_page] = params[:target_page] if params[:target_page]
      set_default_tenant
      do_redirect
    end

    def email_sso
      @tenant = StashEngine::Tenant.find(params[:tenant_id])
      return unless current_user.email&.end_with?(@tenant.authentication&.email_domain)
      return if current_user.email_token && !params.key?(:refresh)

      current_user.create_email_token(tenant_id: @tenant.id)
      current_user.email_token.send_token
    end

    def validate_sso_email
      if current_user.email_token.expired?
        redirect_to email_sso_path(tenant_id: current_user.email_token.tenant_id, refresh: true),
                    flash: { info: 'The code entered has expired. Check your email for a new code.' }
      elsif params[:token].downcase == current_user.email_token.token&.downcase
        current_user.roles.tenant_roles.delete_all if current_user.tenant_id != current_user.email_token.tenant_id
        current_user.update(tenant_id: current_user.email_token.tenant_id, tenant_auth_date: Time.current, validated: true)
        do_redirect
      else
        redirect_to email_sso_path(tenant_id: current_user.email_token.tenant_id), flash: { alert: 'The code is invalid, please try again.' }
      end
    end

    # send the user to the tenant's SSO url
    def sso
      session[:target_page] = params[:target_page] if params[:target_page]
      if StashEngine::Tenant.exists?(params[:tenant_id]&.dig(:value))
        tenant = StashEngine::Tenant.find(params[:tenant_id]&.dig(:value))
        case tenant&.authentication&.strategy
        when 'email'
          redirect_to email_sso_path(tenant_id: tenant.id)
        when 'author_match'
          current_user.roles.tenant_roles.delete_all if current_user.tenant_id != tenant.id
          current_user.update(tenant_id: tenant.id, tenant_auth_date: Time.current)
          do_redirect
        when 'ip_address'
          validate_ip(tenant: tenant) # this redirects internally
        else
          redirect_to tenant.omniauth_login_path(tenant_id: tenant.id)
        end
      else
        render :choose_sso, alert: 'You must select a partner institution from the list.'
      end
    end

    def email_validate
      return unless current_user&.email&.present?
      return if current_user.email_token && !params.key?(:refresh)

      current_user.create_email_token
      current_user.email_token.send_token
    end

    def validate_email
      if current_user.email_token.expired?
        redirect_to email_validate_path(refresh: true), flash: { info: 'The code entered has expired. Check your email for a new code.' }
      elsif params[:token].downcase == current_user.email_token.token&.downcase
        current_user.update(validated: true)
        flash[:notice] = 'Your email has been validated. It can be modified on the My account page.'
        do_redirect
      else
        redirect_to email_validate_path, flash: { alert: 'The code is invalid, please try again.' }
      end
    end

    private

    def callback_basics
      @auth_hash = request.env['omniauth.auth']
      head(:forbidden) unless auth_hash_good
    end

    def set_session
      session.merge!(email: @auth_hash['info']['email'],
                     name: @auth_hash['info']['name'],
                     provider: @auth_hash['provider'])
    end

    def auth_hash_good
      # Identity Providers do not always give us full details in the metadata, and we do not actually use
      # the details. We just want know know that the login was successful.
      @auth_hash['info']['identity_provider'].present?
    end

    # using one controller for multiple orcid login actions (set metadata, log in, orcid_invite so decide which it is before controller)
    def orcid_preprocessor
      @auth_hash = request.env['omniauth.auth']
      @params = request.env['omniauth.params']
      if @params['origin'] == 'feedback'
        session[:target_page] = stash_url_helpers.feedback_path(m: @params['m'], l: @params['l'])
      elsif @params['origin'] == 'metadata'
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
      redirect_to stash_url_helpers.choose_dashboard_path
    end

    # get orcid emails as returned by API
    def orcid_api_emails(orcid:, bearer_token:)
      resp = RestClient.get "#{APP_CONFIG.orcid.api}/v2.1/#{orcid}/email",
                            'Content-type' => 'application/vnd.orcid+json', 'Authorization' => "Bearer #{bearer_token}"
      my_info = JSON.parse(resp.body)
      my_info['email'].map { |item| (item['email'].blank? ? nil : item['email']) }.compact
    rescue RestClient::Exception => e
      logger.error(e)
      []
    end

    def handle_orcid_employments(orcid:, bearer_token:)
      resp = RestClient.get "#{APP_CONFIG.orcid.api}/v2.1/#{orcid}/employments",
                            'Content-type' => 'application/vnd.orcid+json', 'Authorization' => "Bearer #{bearer_token}"
      my_info = JSON.parse(resp.body)
      orgs = my_info['employment-summary'].map { |item| (item['organization'].blank? ? nil : item['organization']) }.compact
      orgs = orgs.map do |org|
        affil = StashDatacite::Affiliation.from_long_name(long_name: org['name'])
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
      update_identifier_metadata(invitation) unless identifier.date_first_published.nil?
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
      id_svc = Stash::Doi::DataciteGen.new(resource: invitation.resource)
      id_svc.update_identifier_metadata!
    end

    def validate_ip(tenant:)
      tenant.authentication.ranges.each do |range|
        net = IPAddr.new(range)
        next unless net.include?(IPAddr.new(request.remote_ip))

        current_user.roles.tenant_roles.delete_all if current_user.tenant_id != tenant.id
        current_user.update(tenant_id: tenant.id, tenant_auth_date: Time.current)
        do_redirect
        return nil # adding nil here to jump out of loop and return early since rubocop sucks & requires a return value
      end

      # else log out and redirect to a page explaining why they can't log in
      logger.warn("Login request failed for #{tenant.id} from #{request.remote_ip}")
      reset_session
      clear_user
      redirect_to stash_url_helpers.ip_error_path
    end

    def do_redirect
      redirect_to email_validate_path and return unless current_user.validated?

      target_page = session[:target_page]
      if target_page.present?
        session[:target_page] = nil
        redirect_to target_page and return
      end
      redirect_to stash_url_helpers.choose_dashboard_path
    end

    def set_default_tenant
      return unless current_user.present?

      current_user.roles.tenant_roles.delete_all if current_user.tenant_id != APP_CONFIG.default_tenant
      current_user.update(tenant_id: APP_CONFIG.default_tenant)
    end
  end
end
# rubocop:enable Metrics/ClassLength
