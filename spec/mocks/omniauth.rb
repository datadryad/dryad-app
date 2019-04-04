module Mocks

  module Omniauth

    def mock_shibboleth!(user)
      # Mocks the Omniauth response from Shibboleth
      raise 'No tenant with id "localhost"; did you run travis-prep.sh?' unless StashEngine::Tenant.exists?('ucop')
      OmniAuth.config.add_mock(:shibboleth, Mocks::Shibboleth.omniauth_response(user))

      # Stub the call to the Shibboleth Service Provider
      stub_request(:get, /Shibboleth\.sso\/Login.*/)
        .to_return(status: 200, body: '', headers: {})
    end

    def mock_orcid!(user)
      # Mocks the Omniauth response from ORCID
      raise 'No tenant with id "localhost"; did you run travis-prep.sh?' unless StashEngine::Tenant.exists?('localhost')
      OmniAuth.config.add_mock(:orcid, Mocks::Orcid.omniauth_response(user))

      # https://api.sandbox.orcid.org/v2.1/5441f05582ea0983f9ad8b683127e6e6/email
      stub_request(:get, /api\.sandbox\.orcid\.org\/.*\/email/)
        .with(
         headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip, deflate',
        'Authorization'=>/Bearer .*/,
        'Content-Type'=>'application/vnd.orcid+json',
        'Host'=>'api.sandbox.orcid.org',
        'User-Agent'=>'rest-client/2.0.2 (darwin18.2.0 x86_64) ruby/2.4.1p111'
         })
        .to_return(status: 200, body: Mocks::Orcid.email_response(user).to_json, headers: {})
    end

  end

end
