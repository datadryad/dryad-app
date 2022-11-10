require 'fileutils'
require 'stash/url_translator'

module StashEngine
  class DataFilesController < GenericFilesController

    def setup_class_info
      @file_model = StashEngine::DataFile
      @resource_assoc = :data_files
    end

  end
end
