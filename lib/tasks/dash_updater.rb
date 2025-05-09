module Tasks
  module DashUpdater

    def self.dash_items_to_update
      # I was going to limit this to items created before transition to the new system, but we may want to update others
      # in order to get thier ROR information updated
      StashEngine::Identifier.joins(:resources).where(pub_state: %w[embargoed published])
        .where("stash_engine_resources.tenant_id <> 'dryad'").distinct
    end

    def self.dryad_items_to_update
      # always order ID
      StashEngine::Identifier.joins(:resources).where(pub_state: %w[embargoed published])
        .where("stash_engine_resources.tenant_id = 'dryad'").order('stash_engine_identifiers.id').distinct
    end

    def self.dated_items_to_update(start, stop)
      StashEngine::Identifier.joins(:resources).where('DATE(stash_engine_resources.publication_date) BETWEEN ? AND ?', start, stop)
        .order('stash_engine_identifiers.id').distinct
    end

    def self.all_items_to_update
      # always order ID
      StashEngine::Identifier.joins(:resources).where(pub_state: %w[embargoed published])
        .order('stash_engine_identifiers.id').distinct
    end

    def self.submit_id_metadata(stash_identifier:, retry_pause: 10)
      resource = stash_identifier.resources.where(meta_view: true).order('id DESC').first
      return if resource.nil?

      idg = Stash::Doi::DataciteGen.new(resource: resource)
      tries = 0

      begin
        idg.update_identifier_metadata!
      rescue Stash::Doi::DataciteGenError => e
        tries += 1
        puts "Try: #{tries} \tStash::Doi::DataciteGen - Unable to submit metadata changes for : '#{resource&.identifier}'"
        puts e.message
        puts ''
        sleep retry_pause # pause for a while to let ezid/datacite stop having problems in case temporary
        retry unless tries > 9
        raise e # re-raise the exception
      end
    end
  end
end
