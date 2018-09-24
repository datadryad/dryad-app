# frozen_string_literal: true

module StashApi
  class Version
    class Metadata

      def initialize(resource:)
        @resource = resource
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def value
        {
          title: @resource.title,
          authors: Authors.new(resource: @resource).value,
          abstract: Abstract.new(resource: @resource).value,
          funders: Funders.new(resource: @resource).value,
          keywords: Keywords.new(resource: @resource).value,
          methods: Methods.new(resource: @resource).value,
          usageNotes: UsageNotes.new(resource: @resource).value,
          locations: Locations.new(resource: @resource).value,
          relatedWorks: RelatedWorks.new(resource: @resource).value,
          versionNumber: @resource.try(:stash_version).try(:version),
          versionStatus: @resource.current_state,
          userId: @resource.user_id,
          skipDataciteUpdate: @resource.skip_datacite_update
        }
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
