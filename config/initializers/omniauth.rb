Rails.application.config.middleware.use OmniAuth::Builder do
#StashEngine::Engine.config.middleware.use OmniAuth::Builder do
  provider :shibboleth,
           :callback_path => '/stash/auth/shibboleth/callback',
           :request_type   => :header,
           #:host            => 'dash2-dev.ucop.edu',
           :host            => StashEngine.app.shib_sp_host,
           :uid_field       => 'eppn',
           :path_prefix     => '/stash/auth',
           :info_fields => {
             :email               => 'mail',
             :identity_provider   => 'shib_identity_provider',
             :first_name          => 'givenName',
             :last_name           => 'sn'
           }

  unless Rails.env.production? || Rails.env.stage?

    provider :developer,
             :callback_path => '/stash/auth/developer/callback',
             :path_prefix => '/stash/auth',
             :fields => [:first_name, :last_name, :email, :test_domain],
             :uid_field => :email
  end

  provider :google_oauth2, StashEngine.app.google_client_id, StashEngine.app.google_client_secret,
      :callback_path  => '/stash/auth/google_oauth2/callback',
      :path_prefix    => '/stash/auth'

  provider :orcid, StashEngine.app.orcid_key, StashEngine.app.orcid_secret,
       :callback_path  => '/stash/auth/orcid/callback',
       :path_prefix    => '/stash/auth',
           :authorize_params => {
               :scope => '/authenticate'
           }
           #:client_options => {
           #    :site => settings.site,
           #    :authorize_url => settings.authorize_url,
           #    :token_url => settings.token_url
           #}

end