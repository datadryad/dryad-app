module Mocks

  module Omniauth

    # rubocop:disable Metrics/MethodLength
    def mock_shibboleth!(user)
      # Mocks the Omniauth response from Shibboleth
      raise 'No tenant with id "localhost"; did you run travis-prep.sh?' unless StashEngine::Tenant.exists?('ucop')
      OmniAuth.config.add_mock(
        :shibboleth,
        uid: user.email || 'tester-foo@dryad.org',
        credentials: {
          token: 'ya30.Ry4gVGVzdHkgTWNUZXN0ZyT5sw'
        },
        info: {
          email: user.email,
          identity_provider: 'localhost'
        }
      )
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def mock_orcid!(user)
      # Mocks the Omniauth response from ORCID
      raise 'No tenant with id "localhost"; did you run travis-prep.sh?' unless StashEngine::Tenant.exists?('localhost')
      OmniAuth.config.add_mock(
        :orcid,
        uid: user.orcid || '555555555555',
        credentials: {
          token: 'ya29.Ry4gVGVzdHkgTWNUZXN0ZmFjZQ'
        },
        info: {
          email: user.email,
          name: user.name,
          test_domain: user.tenant_id || 'localhost'
        },
        extra: {
          raw_info: {
            first_name: user.first_name,
            last_name: user.last_name
          }
        }
      )
    end
    # rubocop:enable Metrics/MethodLength

  end

end
