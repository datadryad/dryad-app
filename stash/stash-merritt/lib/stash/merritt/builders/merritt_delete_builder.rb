require 'stash/repo/file_builder'

module Stash
  module Merritt
    module Builders
      class MerrittDeleteBuilder < Stash::Repo::FileBuilder
        attr_reader :resource_id

        def initialize(resource_id:)
          super(file_name: 'mrt-delete.txt')
          @resource_id = resource_id
        end

        def resource
          @resource ||= StashEngine::Resource.find(resource_id)
        end

        def mime_type
          MIME::Types['text/plain'].first
        end

        def contents
          del_files = resource.data_files.deleted
          del_files.blank? ? nil : del_files.map(&:upload_file_name).join("\n")
        end
      end
    end
  end
end
