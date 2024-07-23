class HealthController < ApplicationController

  def check
    health_status = { status: 'OK' }

    # Check database connectivity
    begin
      StashEngine::Identifier.last
      health_status[:database] = 'connected'
    rescue => e
      health_status[:database] = 'not connected'
      health_status[:database_error] = e.message if params[:advanced]
    end

    # Check Solr connectivity
    begin
      solr = RSolr.connect(url: Blacklight.connection_config[:url])
      solr.get('select', params: {fl: 'dc_identifier_s', rows: 1})
      health_status[:solr] = 'connected'
    rescue => e
      health_status[:solr] = 'not connected'
      health_status[:solr_error] = e.message if params[:advanced]
    end

    # Check AWS S3 connectivity
    begin
      if Stash::Aws::S3.new.exists?(s3_key: 's3_status_check.txt')
        health_status[:aws_s3] = 'connected'
      else
        health_status[:aws_s3] = 'not connected'
        health_status[:aws_s3_error] = 'file does not exist' if params[:advanced]
      end
    rescue => e
      health_status[:aws_s3] = 'not connected'
      health_status[:aws_s3_error] = e.message if params[:advanced]
    end

    status_code = health_status.values.include?('not connected') ? :service_unavailable : :ok
    health_status[:status] = status_code
    render json: health_status, status: status_code
  end
end
