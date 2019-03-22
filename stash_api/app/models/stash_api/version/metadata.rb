# frozen_string_literal: true

module StashApi
  class Version
    class Metadata

      def initialize(resource:)
        @resource = resource
      end

      # rubocop:disable Metrics/AbcSize
      def value
        # setting some false values to nil because they get compacted.  Don't really want to advertise these options for
        # use by others besides ourselves because we don't want others to use them.
        {
          title: @resource.title,
          authors: Authors.new(resource: @resource).value,
          abstract: Abstract.new(resource: @resource).value,
          funders: Funders.new(resource: @resource).value,
          keywords: Keywords.new(resource: @resource).value,
          methods: Methods.new(resource: @resource).value,
          usageNotes: UsageNotes.new(resource: @resource).value,
          locations: Locations.new(resource: @resource).value,
          temporalCoverages: TemporalCoverages.new(resource: @resource).value,
          relatedWorks: RelatedWorks.new(resource: @resource).value,
          versionNumber: @resource.try(:stash_version).try(:version),
          versionStatus: @resource.current_state,
          userId: @resource.user_id,
          skipDataciteUpdate: @resource.skip_datacite_update || nil,
          skipEmails: @resource.skip_emails || nil,
          preserveCurationStatus: @resource.preserve_curation_status || nil,
          loosenValidation: @resource.loosen_validation || nil
        }
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
