require 'stash/sword2'

module StashEngine
  class SubmitResourceJob < ActiveJob::Base
    queue_as :default

    # TODO: can we get the DOI from the resource?
    def perform(zipfile:, doi:, repo:, resource:)
      client = Stash::Sword2::Client.new(collection_uri: repo.endpoint, username: repo.username, password: repo.password)
      if resource.update_uri # update
        client.update(se_iri: resource.update_uri, zipfile: zipfile)
      else # create
        receipt = client.create(doi: doi, zipfile: zipfile)
        resource.download_uri = receipt.em_iri
        resource.update_uri = receipt.se_iri
        resource.save # save download and update URLs for this resource
      end
      # TODO: exception handling
      # TODO: update status in log table
    end
  end
end
