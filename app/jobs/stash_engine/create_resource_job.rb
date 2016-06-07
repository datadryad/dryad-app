require 'stash/sword'

module Stash
  module Sword
    @log = Delayed::Worker.logger
  end
end

module StashEngine
  class CreateResourceJob < ActiveJob::Base
    queue_as :default

    def log
      Delayed::Worker.logger
    end

    # TODO: can we get the DOI from the resource?
    def perform(doi:, zipfile:, resource_id:, sword_params:)
      log.debug("CreateResourceJob: doi: #{doi}, zipfile: #{zipfile}, resource_id: #{resource_id}, sword_params: #{sword_params}")
      request_msg = "Submitting initial #{zipfile} with #{doi} to SWORD; #{(sword_params.map { |k, v| "#{k}: #{v}" }).join(', ')}"
      begin
        resource = Resource.find(resource_id)
        client = Stash::Sword::Client.new(sword_params)
        log.debug("invoking create(doi: #{doi}, zipfile: #{zipfile})")
        receipt = client.create(doi: doi, zipfile: zipfile)
        log.debug("create(doi: #{doi}, zipfile: #{zipfile}) complete")

        log.debug("resource #{resource_id}: download_uri, update_uri = #{receipt.em_iri}, #{receipt.se_iri}")
        resource.download_uri = receipt.em_iri
        resource.update_uri = receipt.se_iri
        resource.save # save download and update URLs for this resource
        log.debug("resource #{resource.id} saved")
        resource.update_version(zipfile)

        resource.update_submission_log(request_msg: request_msg, response_msg: "Success: received EM-IRI #{receipt.em_iri}, SE-IRI #{receipt.se_iri}")
      rescue => e
        log.error(e)
        resource.update_submission_log(request_msg: request_msg, response_msg: "Failed: #{e}")
        raise
      end
    end
  end
end
