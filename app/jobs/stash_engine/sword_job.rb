require 'stash/sword'

module StashEngine
  class SwordJob < ActiveJob::Base
    queue_as :default

    def log
      Delayed::Worker.logger
    end

    def client_for(sword_params)
      Stash::Sword::Client.new(logger: log, **sword_params)
    end

    def describe(doi:, zipfile:)
      raise NoMethodError, "#{self.class} should implement describe(), but it doesn't"
    end

    def make_request(doi:, zipfile:, resource:, client:)
      raise NoMethodError, "#{self.class} should implement make_request(), but it doesn't"
    end

    def perform(doi:, zipfile:, resource_id:, sword_params:)
      log.debug("#{self.class}: doi: #{doi}, zipfile: #{zipfile}, resource_id: #{resource_id}, sword_params: #{sword_params}")
      request_msg = "#{describe(zipfile: zipfile, doi: doi)}; #{(sword_params.map { |k, v| "#{k}: #{v}" }).join(', ')}"

      begin
        resource = Resource.find(resource_id)
        make_request(doi: doi, zipfile: zipfile, resource: resource, client: client_for(sword_params))
        resource.update_version(zipfile)
        resource.update_submission_log(request_msg: request_msg, response_msg: 'Success')
      rescue => e
        log.error(e)
        log.debug(e.backtrace.join("\n")) if e.backtrace
        resource.update_submission_log(request_msg: request_msg, response_msg: "Failed: #{e}")
        raise
      end
    end

  end
end
