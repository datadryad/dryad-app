require_dependency 'stash_engine/application_controller'
require 'fileutils'
require 'stash/url_translator'

module StashEngine
  class SoftwareUploadsController < ApplicationController # rubocop:disable Metrics/ClassLength
    include StashEngine::Concerns::Uploadable

    # attr_reader :resource
    helper_method :resource

  end
end