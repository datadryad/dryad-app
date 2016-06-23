require 'stash/sword'
require 'stash_engine/sword_job'

module StashEngine
  class CreateResourceJob < SwordJob
    def describe(doi:, zipfile:)
      "Initial SWORD submission for DOI #{doi}; zipfile: #{zipfile}"
    end

    def make_request(doi:, zipfile:, resource:, client:)
      log.debug("invoking create(doi: #{doi}, zipfile: #{zipfile}) for resource #{resource.id}")
      receipt = client.create(doi: doi, zipfile: zipfile)
      log.debug("create(doi: #{doi}, zipfile: #{zipfile}) for resource #{resource.id} completed with em_iri #{receipt.em_iri}, edit_iri #{receipt.edit_iri}")
      resource.download_uri = receipt.em_iri
      resource.update_uri = receipt.edit_iri
      resource.save # save download and update URLs for this resource
      log.debug("resource #{resource.id} saved")
    end
  end
end
