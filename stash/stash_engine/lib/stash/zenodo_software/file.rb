module Stash
  module ZenodoSoftware
    class File
      # this take an ActiveRecord StashEngine::SoftwareUpload object
      def initialize(file_obj:)
        @file_obj = file_obj
      end

    end
  end
end
