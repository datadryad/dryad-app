require 'googleauth'
require 'googleauth/stores/file_token_store'

module StashEngine
  class PagesController < ApplicationController
    # the homepage shows latest plans and other things, so more than a static page
    respond_to :js, only: :helpdesk

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
      render status: 404, template: 'stash_engine/pages/app_404'
    end

    def helpdesk
      if current_user || verify_recaptcha
        keywords = JSON.parse(contact_params.to_json, symbolize_names: true)
        if %i[email subject body sname].any? { |k| keywords[k].blank? }
          @message = '<p>Please fill all required fields</p>'
          render 'stash_engine/pages/helpdesk/error', formats: [:js]
        else
          keywords[:id] = StashEngine::Identifier.find(params[:identifier]) if params[:identifier].present?
          Stash::Salesforce.create_email_case(**keywords)
          render 'stash_engine/pages/helpdesk/success', formats: [:js]
        end
      else
        @message = '<p>Please fill in reCAPTCHA</p>'
        render 'stash_engine/pages/helpdesk/error', formats: [:js]
      end
    end

    def contact_params
      params.permit(:email, :subject, :body, :sname)
    end
  end
end
