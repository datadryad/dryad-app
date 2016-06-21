require 'stash/sword'

module StashEngine
  class UpdateResourceJob < ActiveJob::Base
    queue_as :default

    def log
      Delayed::Worker.logger
    end

    def perform(zipfile:, resource_id:, sword_params:)
      log.debug("UpdateResourceJob: zipfile: #{zipfile}, resource_id: #{resource_id}, sword_params: #{sword_params}")
      request_msg = "Submitting update #{zipfile} to SWORD; #{(sword_params.map { |k, v| "#{k}: #{v}" }).join(', ')}"
      begin
        resource = Resource.find(resource_id)
        client = Stash::Sword::Client.new(logger: log, **sword_params)

        update_uri = resource.update_uri
        request_msg << ", edit_iri: #{update_uri}"

        log.debug("invoking update(edit_iri: #{update_uri}, zipfile: #{zipfile})")
        client.update(edit_iri: update_uri, zipfile: zipfile)
        log.debug("update(edit_iri: #{update_uri}, zipfile: #{zipfile}) complete")

        resource.update_version(zipfile)
        resource.update_submission_log(request_msg: request_msg, response_msg: "Success")
      rescue => e
        log.error(e)
        log.debug(e.backtrace.join("\n")) if e.backtrace
        resource.update_submission_log(request_msg: request_msg, response_msg: "Failed: #{e}")
      end
    end
  end
end
