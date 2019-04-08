require_dependency 'stash_datacite/application_controller'
require 'httparty'
require 'stash/import/cross_ref'

module StashDatacite
  class PublicationsController < ApplicationController
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def update
      @se_id = StashEngine::Identifier.find(params[:internal_datum][:identifier_id])
      save_form_to_internal_data
      respond_to do |format|
        format.js do
          if params[:internal_datum][:do_import] == 'true'
            @resource = @se_id.latest_resource
            update_manuscript_metadata if !@msid&.value.blank? && params[:import_type] == 'manuscript'
            update_doi_metadata if !@doi&.value.blank? && params[:import_type] == 'published'
            @error = 'Please fill in the form completely' if @msid&.value.blank? && @doi&.value.blank?
          else
            render template: 'stash_datacite/shared/update.js.erb'
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    def save_form_to_internal_data
      @pub_issn = manage_internal_datum(identifier: @se_id, data_type: 'publicationISSN', value: params[:internal_datum][:publication_issn])
      @msid = manage_internal_datum(identifier: @se_id, data_type: 'manuscriptNumber', value: params[:internal_datum][:msid])
      @doi = manage_internal_datum(identifier: @se_id, data_type: 'publicationDOI', value: params[:internal_datum][:doi])
    end

    # rubocop:disable Lint/UnreachableCode
    def update_manuscript_metadata
      # this all needs rework, but waiting on new api
      @error = 'Could not retrieve manuscript data.'
      return

      # the rest of this is just here temporarily not sure if Ryan's new api will be like this or different
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
    # rubocop:enable Lint/UnreachableCode

    def update_doi_metadata
      if @doi.value.blank?
        @error = 'Please enter a DOI to import metadata'
        return
      end
      works = Serrano.works(ids: @doi.value)
      if !works.is_a?(Array) || works.first['message'].blank?
        @error = "We couldn't obtain information from CrossRef about this DOI"
        return
      end
      xr_import = Stash::Import::CrossRef.new(resource: @resource, serrano_message: works.first['message'])
      xr_import.populate
    rescue Serrano::NotFound, Serrano::BadGateway, Serrano::Error, Serrano::GatewayTimeout, Serrano::InternalServerError, Serrano::ServiceUnavailable
      @error = "We couldn't retrieve information from CrossRef about this DOI"
    end

    def manage_internal_datum(identifier:, data_type:, value:)
      datum = StashEngine::InternalDatum.where(stash_identifier: identifier, data_type: data_type).first
      if datum.present?
        datum.destroy if value.blank?
        datum.update(value: value) unless value.blank?
      else
        datum = StashEngine::InternalDatum.create(stash_identifier: identifier, data_type: data_type, value: value)
      end
      datum
    end
  end
end
