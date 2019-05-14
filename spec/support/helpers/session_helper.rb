module SessionsHelper

  include Mocks::Omniauth
  include Mocks::Ror

  def sign_in(user = create(:user), with_shib = false)
    sign_out if have_text('Logout')
    case user
    when StashEngine::User
      sign_in_as_user(user, with_shib)
    when Symbol
      sign_in_as_user(create(:user), with_shib)
    else
      raise ArgumentError, "Invalid argument user: #{user}"
    end
  end

  def sign_out
    visit stash_url_helpers.sessions_destroy_path
  end

  # rubocop:disable Metrics/MethodLength
  def sign_in_as_user(user, with_shib)
    mock_orcid!(user)
    mock_ror!
    OmniAuth.config.test_mode = true
    visit root_path
    click_link 'Login'
    click_link 'Login or create your ORCID iD'
    if with_shib
      # mock_shibboleth!(user)
      # find('#tenant_id').find('option:last-child').select_option
      # click_button 'Login to verify'
      # TODO: figure out how to properly handle the Shibboleth SP redirection
      click_link 'Continue to My Datasets'
    elsif user.tenant_id.blank?
      click_link 'Continue to My Datasets'
    end
  end
  # rubocop:enable Metrics/MethodLength

end
