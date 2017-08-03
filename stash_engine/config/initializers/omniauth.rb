Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shibboleth,
           :callback_path => '/stash/auth/shibboleth/callback',
           :request_type   => :header,
           :host            => StashEngine.app.shib_sp_host,
           :uid_field       => 'eppn',
           :path_prefix     => '/stash/auth',
           :info_fields => {
             :email               => 'mail',
             :identity_provider   => 'shib_identity_provider'
           }

  unless Rails.env.production? || Rails.env.stage?

    provider :developer,
             :callback_path => '/stash/auth/developer/callback',
             :path_prefix => '/stash/auth',
             :fields => [:name, :email, :test_domain],
             :uid_field => :email
  end

  provider :google_oauth2, StashEngine.app.google_client_id, StashEngine.app.google_client_secret,
      :callback_path  => '/stash/auth/google_oauth2/callback',
      :path_prefix    => '/stash/auth'

  provider :orcid, StashEngine.app.orcid_key, StashEngine.app.orcid_secret,
    :member => StashEngine.app.member,
    :sandbox => StashEngine.app.sandbox,
    :callback_path => '/stash/auth/orcid/callback',
    # :callback_url  => "#{request.base_url}/stash/auth/orcid/callback",
    :path_prefix    => '/stash/auth',
    :authorize_params => {
      :scope => '/authenticate'
    }
    # I think all of these are unused and are leftover garbage
    #:client_options => {
    #   :site => StashEngine.app.orcid_site,
    #   :authorize_url => StashEngine.app.orcid_authorize_url,
    #   :token_url => StashEngine.app.orcid_token_url
    #}
  ## Omniauth on_failure behavior to work for all ENV including localhost
  OmniAuth.config.on_failure = -> (env) do
    Rack::Response.new(['302 Moved'], 302, 'Location' => env['omniauth.origin'] || "/").finish
  end
end

