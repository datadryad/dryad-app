require 'stash/sword'

module Sword
  @log = Delayed::Worker.logger
end

module StashEngine
  class SubmitResourceJob < ActiveJob::Base
    queue_as :default

    def log
      Delayed::Worker.logger
    end

    # TODO: can we get the DOI from the resource?
    def perform(zipfile:, doi:, repo:, resource:)
      log.debug("SubmitResourceJob: zipfile: #{zipfile}, doi: #{doi}, repo: #{repo ? repo.endpoint : 'nil'}, resource: #{resource ? resource.id : 'nil'}")
      client = Stash::Sword::Client.new(collection_uri: repo.endpoint, username: repo.username, password: repo.password)
      if resource.update_uri # update
        log.debug("invoking update(se_iri: #{resource.update_uri}, zipfile: #{zipfile})")

        client.update(se_iri: resource.update_uri, zipfile: zipfile)

        log.debug("update(se_iri: #{resource.update_uri}, zipfile: #{zipfile}) complete")
      else # create
        log.debug("invoking create(doi: #{doi}, zipfile: #{zipfile})")

        receipt = client.create(doi: doi, zipfile: zipfile)

        log.debug("create(doi: #{doi}, zipfile: #{zipfile}) complete")

        resource.download_uri = receipt.em_iri
        resource.update_uri = receipt.se_iri

        log.debug("resource #{resource.id}: download_uri, update_uri = #{receipt.em_iri}, #{receipt.se_iri}")

        resource.save # save download and update URLs for this resource

        log.debug("resource #{resource.id} saved")
      end

      # TODO: exception handling
      # TODO: update status in log table
    end
  end
end
