if Rails.env.test?
  Sidekiq.default_configuration do |config|
    config.redis = ::MockRedis.new
  end
else
  Sidekiq.configure_server do |config|
    config.redis = { url: APP_CONFIG[:cache][:app_url] }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: APP_CONFIG[:cache][:app_url] }
  end
end
