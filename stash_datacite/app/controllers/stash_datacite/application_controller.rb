require 'error/error_handler'

module StashDatacite
  class ApplicationController < ::ApplicationController
    helper StashEngine::ApplicationHelper

    include StashEngine::SharedController

    include Error::ErrorHandler
  end
end
