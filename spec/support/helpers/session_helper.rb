module SessionsHelper

  include Mocks::Omniauth
  include Mocks::CurationActivity

  # rubocop:disable Style/OptionalBooleanParameter
  def sign_in(user = create(:user), with_shib = false)
    visit root_path
    expect(page).to have_css('.o-banner__tagline', text: 'Trusted, simple, community driven')
    sign_out if have_text('User settings')
    expect(page).to have_css('.o-banner__tagline', text: 'Trusted, simple, community driven')
    case user
    when StashEngine::User
      sign_in_as_user(user, with_shib)
    when Symbol
      sign_in_as_user(create(:user), with_shib)
    else
      raise ArgumentError, "Invalid argument user: #{user}"
    end
  end
  # rubocop:enable Style/OptionalBooleanParameter

  def sign_out
    safe_visit stash_url_helpers.sessions_destroy_path
  end

  def sign_in_as_user(user, with_shib)
    mock_orcid!(user)
    ignore_zenodo!
    OmniAuth.config.test_mode = true
    visit root_path
    click_link 'Login'
    click_link 'Login or create your ORCID iD'
    sleep 0.1
    nil unless with_shib || user.tenant_id.blank?
  end

  def safe_visit(url)
    max_retries = 3
    times_retried = 0
    begin
      visit url
    rescue Net::ReadTimeout => e
      if times_retried < max_retries
        times_retried += 1
        logger.info("Failed to visit #{current_url}, retry #{times_retried}/#{max_retries}")
        retry
      else
        logger.error(e.full_message)
        exit(1)
      end
    end
  end

end
