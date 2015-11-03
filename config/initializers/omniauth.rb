Rails.application.config.middleware.use OmniAuth::Builder do
#StashEngine::Engine.config.middleware.use OmniAuth::Builder do
  provider :shibboleth,
           :callback_path => '/stash/auth/shibboleth/callback',
           :request_type   => :header,
           #:host            => 'dash2-dev.ucop.edu',
           :host            => APP_CONFIG.shib_sp_host,
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
             :fields => [:name, :email],
             :uid_field => :email
  end

end