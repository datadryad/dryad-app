require 'stash/url_translator'

module StashEngine
  class SoftwareFilesController < GenericFilesController

    def setup_class_info
      @file_model = StashEngine::SoftwareFile
      @resource_assoc = :software_files
    end

  end
end
