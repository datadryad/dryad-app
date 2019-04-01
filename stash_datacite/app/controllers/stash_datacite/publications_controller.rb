require_dependency 'stash_datacite/application_controller'
require 'httparty'

module StashDatacite
  class PublicationsController < ApplicationController
    # include HTTParty

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def update
      @se_id = StashEngine::Identifier.find(params[:internal_datum][:identifier_id])
      save_form_to_internal_data
      respond_to do |format|
        format.js do
          if params[:internal_datum][:do_import] == 'true'
            # take action to do the actual import and reload the page with javascript
            if @doi.value.blank? && !@msid.value.blank?
              update_manuscript_metadata
            else
              update_doi_metadata
            end
            render 'update' # just the standard update in the associated view directory
          else
            render template: 'stash_datacite/shared/update.js.erb'
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def save_form_to_internal_data
      @pub_issn = StashEngine::InternalDatum.where(stash_identifier: @se_id, data_type: 'publicationISSN').first_or_create
      @pub_issn.update(value: params[:internal_datum][:publication_issn]) unless params[:internal_datum][:publication_issn].blank?

      @msid = StashEngine::InternalDatum.where(stash_identifier: @se_id, data_type: 'manuscriptNumber').first_or_create
      @msid.update(value: params[:internal_datum][:msid]) unless params[:internal_datum][:msid].blank?

      @doi = StashEngine::InternalDatum.where(stash_identifier: @se_id, data_type: 'publicationDOI').first_or_create
      @doi.update(value: params[:internal_datum][:doi]) unless params[:internal_datum][:msid].blank?
    end

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
    end

    def update_doi_metadata
      url = 'https://api.crossref.org/works/doi:[replaceme]/transform/application/vnd.crossref.unixref+xml'
      results = HTTParty.get(url,
                             query: { query: affil },
                             headers: { 'Content-Type' => 'application/json' })
    rescue HTTParty::Error, SocketError => ex
      logger.error("Unable to get results from crossRef for #{@doi.value}: #{ex}")
    end
  end
end
