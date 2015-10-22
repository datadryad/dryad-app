Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shibboleth,
           {
               :request_type   => :header,
               :host            => 'dash2-dev.ucop.edu',
               :callback_path   => '/stash/auth/:provider/callback',
               :uid_field       => 'eppn',
               #:debug           =>  true,
               :info_fields => {
                   :email               => 'mail',
                   :identity_provider   => 'shib_identity_provider'
               }
           }
end