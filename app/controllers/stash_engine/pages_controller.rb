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

    def helpdesk
      keywords = JSON.parse(contact_params.to_json, symbolize_names: true)
      return nil if keywords.any? { |_k, v| v.empty? }

      keywords[:id] = StashEngine::Identifier.find(params[:identifier]) if params[:identifier].present?
      Stash::Salesforce.create_email_case(**keywords)
      render js: "var cform = document.getElementById('contact_form')\n
        cform.innerHTML = '<p>Your query has been submitted to the Dryad helpdesk.</p>'\n
        cform.classList.add('alt')"
    end

    def contact_params
      params.permit(:email, :subject, :body, :sname)
    end
  end
end
