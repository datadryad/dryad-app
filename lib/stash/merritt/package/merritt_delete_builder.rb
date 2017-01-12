require 'stash/repo/util/file_builder'

module Stash
  module Merritt
    module Package
      class MerrittDeleteBuilder < Stash::Repo::Util::FileBuilder
        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        def file_name
          'mrt-delete.xml'
        end

        def contents
          del_files = resource.file_uploads.deleted
          del_files.blank? ? nil : del_files.map(&:upload_file_name).join("\n")
        end
      end
    end
  end
end
