require 'googleauth'
require 'googleauth/stores/file_token_store'

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
      if current_user || verify_recaptcha
        keywords = JSON.parse(contact_params.to_json, symbolize_names: true)
        if %i[email subject body sname].any? { |k| keywords[k].blank? }
          render js: "var cform = document.getElementById('contact_form')\n
            var error = document.createElement('div')
            error.classList.add('callout', 'err')
            error.innerHTML = '<p>Please fill all required fields</p>'
            cform.prepend(error)"
        else
          keywords[:id] = StashEngine::Identifier.find(params[:identifier]) if params[:identifier].present?
          Stash::Salesforce.create_email_case(**keywords)
          render js: "var cform = document.getElementById('contact_form')\n
            cform.innerHTML = '<div class=\"callout alt\"><p>Your query has been submitted to the Dryad helpdesk.</p></div>'\n"
        end
      else
        render js: "var cform = document.getElementById('contact_form')\n
          var error = document.createElement('div')
          error.classList.add('callout', 'err')
          error.innerHTML = '<p>Please fill in reCAPTCHA</p>'
          cform.prepend(error)"
      end
    end

    def contact_params
      params.permit(:email, :subject, :body, :sname)
    end
  end
end
