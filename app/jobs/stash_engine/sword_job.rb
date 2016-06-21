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

    # TODO: make this less inside-out
    def make_request(zipfile:, resource_id:, sword_params:, desc:, &block)
      log.debug("#{self.class}: zipfile: #{zipfile}, resource_id: #{resource_id}, sword_params: #{sword_params}")
      request_msg = "#{desc}; #{(sword_params.map { |k, v| "#{k}: #{v}" }).join(', ')}"
      begin
        resource = Resource.find(resource_id)
        yield resource, client_for(sword_params)

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
