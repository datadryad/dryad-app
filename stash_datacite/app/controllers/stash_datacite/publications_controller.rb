require_dependency 'stash_datacite/application_controller'
require 'httparty'
require 'stash/import/cross_ref'

module StashDatacite
  class PublicationsController < ApplicationController
    # include HTTParty
    def update
      @se_id = StashEngine::Identifier.find(params[:internal_datum][:identifier_id])
      save_form_to_internal_data
      respond_to do |format|
        format.js do
          if params[:internal_datum][:do_import] == 'true'
            # take action to do the actual import and reload the page with javascript
            @resource = @se_id.latest_resource
            if @doi.value.blank? && !@msid.value.blank?
              update_manuscript_metadata
            else
              update_doi_metadata
            end
          else
            render template: 'stash_datacite/shared/update.js.erb'
          end
        end
      end
    end
    # rubocop:enable

    # rubocop:disable Metrics/AbcSize
    def save_form_to_internal_data
      @pub_issn = StashEngine::InternalDatum.where(stash_identifier: @se_id, data_type: 'publicationISSN').first_or_create
      @pub_issn.update(value: params[:internal_datum][:publication_issn]) unless params[:internal_datum][:publication_issn].blank?

      @msid = StashEngine::InternalDatum.where(stash_identifier: @se_id, data_type: 'manuscriptNumber').first_or_create
      @msid.update(value: params[:internal_datum][:msid]) unless params[:internal_datum][:msid].blank?

      @doi = StashEngine::InternalDatum.where(stash_identifier: @se_id, data_type: 'publicationDOI').first_or_create
      @doi.update(value: params[:internal_datum][:doi]) unless params[:internal_datum][:doi].blank?
    end
    # rubocop:enable Metrics/AbcSize

    def update_manuscript_metadata
      pub_issn_only = @pub_issn.value
      msid_only = @msid.value
      body = { dryadDOI: 'doi:' + @se_id.identifier,
               dashUserID: current_user.id,
               manuscriptNumber: msid_only }.to_json
      url = "#{APP_CONFIG.old_dryad_url}/api/v1/journals/#{pub_issn_only}/packages/"
      @results = HTTParty.put(url,
                              query: { access_token: APP_CONFIG.old_dryad_access_token },
                              body: body,
                              headers: { 'Content-Type' => 'application/json' })
      render 'update' # just the standard update in the associated view directory
    end

    def update_doi_metadata
      if @doi.value.blank?
        @error = 'Please enter a DOI to import metadata'
        return
      end
      works = Serrano.works(ids: @doi.value)
      if !works.is_a?(Array) || works.first['message'].blank?
        @error = "Couldn't obtain information from CrossRef about this DOI"
        return
      end
      xr_import = Stash::Import::CrossRef.new(resource: @resource, serrano_message: works.first['message'])
      xr_import.populate
    rescue Serrano::NotFound, Serrano::BadGateway, Serrano::Error, Serrano::GatewayTimeout, Serrano::InternalServerError, Serrano::ServiceUnavailable
      @error = "We couldn't retrieve information from CrossRef about this DOI"
    end
  end
end
