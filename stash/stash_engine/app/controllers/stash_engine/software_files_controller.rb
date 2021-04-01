require_dependency 'stash_engine/application_controller'
require 'stash/url_translator'

module StashEngine
  class SoftwareFilesController < ApplicationController

    def setup_class_info
      @file_model = StashEngine::SoftwareFile
      @resource_assoc = :software_files
    end

    include StashEngine::Concerns::Uploadable

    # attr_reader :resource
    helper_method :resource

  end
end
