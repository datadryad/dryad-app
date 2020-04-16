require_dependency 'stash_engine/application_controller'
require 'fileutils'
require 'stash/url_translator'

module StashEngine
  class SoftwareUploadsController < ApplicationController # rubocop:disable Metrics/ClassLength
    def file_model
      StashEngine::SoftwareUpload
    end

    def resource_assoc
      :software_uploads
    end

    include StashEngine::Concerns::Uploadable

    # attr_reader :resource
    helper_method :resource

    def ensure_upload_dir(resource_id)
      @upload_dir = StashEngine::Resource.software_upload_dir_for(resource_id)
      FileUtils.mkdir_p @upload_dir unless File.exist?(@upload_dir)
    end

  end
end