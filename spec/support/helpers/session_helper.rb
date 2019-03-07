module SessionsHelper

  def sign_in(user = :user)
    case user
    when StashEngine::User
      sign_in_as_user(user)
    when Symbol
      sign_in_as_user(create(:user))
    else
      raise ArgumentError, "Invalid argument user: #{user}"
    end
  end

  def sign_in_as_user(user)
    clear_cookies!
    mock_omniauth!(user)
    visit '/'
    first(:link_or_button, 'Login').click
    first(:link_or_button, 'Login or create your ORCID iD').click
    first(:link_or_button, 'Continue to My Datasets').click
  end

  def mock_omniauth!(user)
    raise "No tenant with id 'localhost'; did you run travis-prep.sh?" unless StashEngine::Tenant.exists?('localhost')

    OmniAuth.config.test_mode = true
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

end
