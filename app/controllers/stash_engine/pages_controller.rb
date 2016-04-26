require_dependency 'stash_engine/application_controller'

module StashEngine
  class PagesController < ApplicationController
    # the homepage shows latest plans and other things, so more than a static page
    def home
    end

    # The help controller uses the standard app layout, so the default is here.
    # Perhaps specific views would override it in the base application.
    def help
    end
  end
end
