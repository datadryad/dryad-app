require 'stash/sword'
require 'stash_engine/sword_job'

module StashEngine
  class UpdateResourceJob < SwordJob
    def describe(doi:, zipfile:)
      "SWORD update for DOI #{doi}; zipfile: #{zipfile}"
    end

    def make_request(doi:, zipfile:, resource:, client:)
      update_uri = resource.update_uri
      log.debug("invoking update(edit_iri: #{update_uri}, zipfile: #{zipfile}) for resource #{resource.id}")
      status = client.update(edit_iri: update_uri, zipfile: zipfile)
      log.debug("update(edit_iri: #{update_uri}, zipfile: #{zipfile}) for resource #{resource.id} completed with status #{status}")
    end
  end
end
