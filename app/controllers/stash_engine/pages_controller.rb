module StashEngine
  class PagesController < ApplicationController
    # the homepage shows latest plans and other things, so more than a static page
    def home
      @dataset_count = Resource.submitted_dataset_count
      @hostname = request.host
    end

    # produces a sitemap for the domain name/tenant listing the released datasets
    # TODO: change page to display all that are embargoed or published, not repo status and cache the doc so it's not too heavy
    def sitemap
      respond_to do |format|
        format.xml do
          sm = SiteMap.new
          if params[:page].nil?
            render xml: sm.sitemap_index, layout: false
          else
            render xml: sm.sitemap_page(params[:page]), layout: false
          end
        end
      end
    end

    # an application 404 page to make it look nicer
    def app_404
      render status: :not_found
    end
  end
end
