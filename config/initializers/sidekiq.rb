Sidekiq.configure_server do |config|
  config.redis = { url: APP_CONFIG[:cache][:app_url] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: APP_CONFIG[:cache][:app_url] }
end
