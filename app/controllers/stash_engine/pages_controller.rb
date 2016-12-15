require_dependency 'stash_engine/application_controller'

module StashEngine
  class PagesController < ApplicationController
    # the homepage shows latest plans and other things, so more than a static page
    def home
      @dataset_count = Resource.submitted_dataset_count
    end

    # The help controller uses the standard app layout, so the default is here.
    # Perhaps specific views would override it in the base application.
    def help
    end

    # The about controller uses the standard app layout, so the default is here.
    # Perhaps specific views would override it in the base application.
    def about
    end

    # an application 404 page to make it look nicer
    def app_404
      render :status => :not_found
    end
  end
end
