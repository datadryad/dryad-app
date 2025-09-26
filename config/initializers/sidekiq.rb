# frozen_string_literal: true

require "sidekiq"
require "sidekiq-unique-jobs"

log_file_path = Rails.root.join('log', 'sidekiq.log')
sidekiq_logger = Logger.new(log_file_path)
sidekiq_logger.level = Logger::INFO
sidekiq_logger.formatter = Sidekiq::Logger::Formatters::Pretty.new

Sidekiq.default_job_options = {
  'backtrace' => true,
  'retry' => true
}

if Rails.env.test?
  Sidekiq.default_configuration do |config|
    config.redis = ::MockRedis.new
  end
else
  Sidekiq.configure_server do |config|
    config.redis = { url: APP_CONFIG[:cache][:app_url], ssl: !Rails.env.development? }
    config.logger = sidekiq_logger

    config.client_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Client
    end

    config.server_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Server
    end

    SidekiqUniqueJobs::Server.configure(config)
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: APP_CONFIG[:cache][:app_url], ssl: !Rails.env.development? }
    config.logger = sidekiq_logger

    config.client_middleware do |chain|
      chain.add SidekiqUniqueJobs::Middleware::Client
    end
  end
end

SidekiqUniqueJobs.configure do |config|
  config.debug_lua = Rails.env.development? # Turn on when debugging
  config.lock_info = Rails.env.development? # Turn on when debugging
  config.lock_timeout = nil # turn off lock timeout
end
