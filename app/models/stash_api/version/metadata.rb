# frozen_string_literal: true

module StashApi
  class Version
    class Metadata

      def initialize(resource:, item_view: false, post: false) # item view may present additional information not shown in list view
        @resource = resource
        @item_view = item_view
        @post = post
      end

      # rubocop:disable Metrics/AbcSize
      def value
        # setting some false values to nil because they get compacted.  Don't really want to advertise these options for
        # use by others besides ourselves because we don't want others to use them.
        vals = {
          title: @resource.title,
          authors: Authors.new(resource: @resource).value,
          abstract: Abstract.new(resource: @resource).value,
          funders: Funders.new(resource: @resource).value,
          keywords: Keywords.new(resource: @resource).value,
          fieldOfScience: @resource.subjects.fos.first&.subject,
          methods: Methods.new(resource: @resource).value,
          usageNotes: UsageNotes.new(resource: @resource).value,
          locations: Locations.new(resource: @resource).value,
          temporalCoverages: TemporalCoverages.new(resource: @resource).value,
          relatedWorks: RelatedWorks.new(resource: @resource).value,
          versionNumber: @resource.try(:stash_version).try(:version),
          versionStatus: @resource.current_state,
          curationStatus: StashEngine::CurationActivity.latest(resource: @resource)&.readable_status,
          versionChanges: version_changes,
          publicationDate: @resource.publication_date&.strftime('%Y-%m-%d'),
          lastModificationDate: @resource.updated_at&.utc&.strftime('%Y-%m-%d'),
          visibility: visibility,
          sharingLink: sharing_link,
          skipDataciteUpdate: @resource.skip_datacite_update || nil,
          skipEmails: @resource.skip_emails || nil,
          preserveCurationStatus: @resource.preserve_curation_status || nil,
          loosenValidation: @resource.loosen_validation || nil
        }
        vals[:changedFields] = changed_fields if @item_view
        vals[:userId] = @resource.user_id if @post
        vals
      end
      # rubocop:enable Metrics/AbcSize

      def version_changes
        return 'none' if @resource.stash_version.version == 1

        file_states = @resource.generic_files&.map(&:file_state)
        return 'files_changed' if file_states && (file_states - ['copied']).present?

        'metadata_changed'
      end

      # gives a list of the fields that have changed
      def changed_fields
        items = @resource.changed_from_previous_curated
        return ['none'] unless items.present?

        items
      end

      def visibility
        if @resource.meta_view || @resource.file_view
          'public'
        else
          'restricted'
        end
      end

      def sharing_link
        curation_activity = StashEngine::CurationActivity.latest(resource: @resource)
        case curation_activity.status
        when 'published'
          Rails.application.routes.url_helpers.show_url(@resource&.identifier_str.to_s)
        when 'in_progress'
          # if it's in_progress, return the sharing_link for the previous submitted version
          prev_submitted_res = @resource&.identifier&.last_submitted_resource
          prev_submitted_res&.identifier&.shares&.first&.sharing_link
        when 'embargoed', 'withdrawn'
        # suppress the link -- even if the user has the rights to view
        # the metadata, they should not be downloading it
        else
          @resource&.identifier&.shares&.first&.sharing_link
        end
      end
    end
  end
end
