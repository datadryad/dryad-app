Recaptcha.configure do |config|
  config.site_key  = APP_CONFIG.google_recaptcha_sitekey
  config.secret_key = APP_CONFIG.google_recaptcha_secret
end