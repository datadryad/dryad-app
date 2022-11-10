require 'fileutils'
require 'stash/url_translator'

module StashEngine
  class SuppFilesController < GenericFilesController

    def setup_class_info
      @file_model = StashEngine::SuppFile
      @resource_assoc = :supp_files
    end

  end
end
