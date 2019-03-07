module SessionsHelper

  include Mocks::Omniauth

  def sign_in(user = :user, with_shib = false)
    case user
    when StashEngine::User
      sign_in_as_user(user, with_shib)
    when Symbol
      sign_in_as_user(create(:user), with_shib)
    else
      raise ArgumentError, "Invalid argument user: #{user}"
    end
  end

  def sign_in_as_user(user, with_shib)
    OmniAuth.config.test_mode = true
    mock_orcid!(user)

    visit root_path
    click_link 'Login'
    click_link 'Login or create your ORCID iD'

    if with_shib
      # TODO: get the shib login working
      # mock_shibboleth!(user)
      # select 'ucop', from: 'tenant_id'
      # click_button 'Login to verify'
    elsif user.tenant_id.blank?
      click_link 'Continue to My Datasets'
    end
  end

end
