class HealthController < ApplicationController

  def check
    @health_status = {}
    populate_statuses

    status_code = @health_status.map { |_k, v| v[:status] }.include?('not connected') ? :service_unavailable : :ok
    notify_health_status_change(status_code, @health_status)

    render json: { status: status_code }.merge(@health_status), status: status_code and return if params.key?(:advanced)

    render json: { status: status_code }.merge(simple_response_hash), status: status_code
  end

  private

  def simple_response_hash
    return @simple_response_hash if @simple_response_hash

    @simple_response_hash = @health_status.each_with_object({}) do |(key, value), result|
      result[key] = value[:status]
    end
  end

  def populate_statuses
    # Check database connectivity
    @health_status[:database] = {}
    begin
      StashEngine::Identifier.last
      @health_status[:database][:status] = 'connected'
    rescue StandardError => e
      @health_status[:database][:status] = 'not connected'
      @health_status[:database][:error] = e.message
    end

    # Check Solr connectivity
    @health_status[:solr] = {}
    begin
      solr = RSolr.connect(url: APP_CONFIG.solr_url)
      solr.get('select', params: { fl: 'dc_identifier_s', rows: 1 })
      @health_status[:solr][:status] = 'connected'
    rescue StandardError => e
      @health_status[:solr][:status] = 'not connected'
      @health_status[:solr][:error] = e.message
    end

    # Check AWS S3 connectivity
    @health_status[:aws_s3] = {}
    begin
      if Stash::Aws::S3.new.exists?(s3_key: 's3_status_check.txt')
        @health_status[:aws_s3][:status] = 'connected'
      else
        @health_status[:aws_s3][:status] = 'not connected'
        @health_status[:aws_s3][:error] = 'file does not exist'
      end
    rescue StandardError => e
      @health_status[:aws_s3][:status] = 'not connected'
      @health_status[:aws_s3][:error] = e.message
    end
  end

  def notify_health_status_change(status_code, health_status)
    old_statuses = Rails.cache.read('health_status')
    Rails.cache.write('health_status', simple_response_hash, expires_in: 10.minute)
    return if old_statuses == simple_response_hash

    StashEngine::NotificationsMailer.health_status_change(status_code, health_status).deliver_now
  end
end
