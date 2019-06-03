# Why do things this way?
# http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/
# http://www.jetthoughts.com/blog/tech/2014/08/14/cleaning-up-your-rails-views-with-view-objects.html
module StashDatacite
  class ResourcesController
    class DatasetPresenter
      attr_reader :resource

      delegate :updated_at, :user_id, to: :resource

      def initialize(resource)
        @resource = resource
        @completions = Resource::Completions.new(@resource)
      end

      def title
        return '[No title supplied]' if @resource.title.blank?
        @resource.title
      end

      def status
        @resource.current_state
      end

      # according to https://dash.ucop.edu/xtf/search?smode=metadataBasicsPage
      # required fields are Title, Institution, Data type, Data Author(s), Abstract
      def required_filled
        @completions.required_completed
      end

      def required_total
        @completions.required_total
      end

      # according to https://dash.ucop.edu/xtf/search?smode=metadataBasicsPage
      # optional fields are Date, Keywords, Methods, Citations
      def optional_filled
        @completions.optional_completed
      end

      def optional_total
        @completions.optional_total
      end

      def file_count
        @resource.current_file_uploads.count
      end

      # size is the size of the whole dataset, all versions
      def size
        return 0 if @resource.identifier.nil?
        @resource.identifier.storage_size || 0
      end

      def external_identifier
        id = @resource.identifier
        if id.blank?
          'bad_identifier'
        else
          "#{id.try(:identifier_type).try(:downcase)}:#{id.try(:identifier)}"
        end
      end

      def embargo_status
        @resource&.current_curation_activity&.status
      end

      def embargo_status_pretty
        return 'Processing' if @resource&.current_resource_state.resource_state == 'error'
        @resource&.current_curation_activity&.readable_status
      end

      def publication_date
        @resource.publication_date
      end

      def edited_by_id
        return @resource.user_id if @resource.current_editor_id.nil?
        @resource.current_editor_id
      end

      def edited_by_name
        u = resource.editor
        u = resource.user if u.nil?
        "#{u.first_name} #{u.last_name}"
      end

      def edited_by_name_w_role
        return edited_by_name if resource.current_editor_id.nil? || resource.user_id == resource.current_editor_id
        "#{edited_by_name} (admin)"
      end

      def version
        return 1 if @resource.stash_version.nil?
        @resource.stash_version.version
      end

      # edit history comment, only one per resource (v) right now, but may have more history per version if/when we expand event we track
      def comment
        return '' if @resource.edit_histories.empty?
        @resource.edit_histories.first.user_comment.to_s
      end

      def resource_created_at
        @resource.created_at
      end

      def created_at
        @resource.identifier.try(:created_at) || @resource.created_at
      end
    end
  end
end
