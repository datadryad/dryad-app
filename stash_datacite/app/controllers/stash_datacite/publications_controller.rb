require_dependency 'stash_datacite/application_controller'
require 'httparty'
require 'stash/import/cross_ref'
require 'stash/import/dryad_manuscript'
require 'cgi'

module StashDatacite
  class PublicationsController < ApplicationController
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def update
      @se_id = StashEngine::Identifier.find(params[:internal_datum][:identifier_id])

p '=============== UPDATING! =========================='

      save_form_to_internal_data
      respond_to do |format|
        format.js do
          if params[:internal_datum][:do_import] == 'true'
            @error = 'Please fill in the form completely' if params[:internal_datum][:msid].blank? && params[:internal_datum][:doi].blank?
            @resource = @se_id.latest_resource
            update_manuscript_metadata if params[:import_type] == 'manuscript'
            update_doi_metadata if !@doi&.value.blank? && params[:import_type] == 'published'
          else
            render template: 'stash_datacite/shared/update.js.erb'
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    def save_form_to_internal_data
      @pub_issn = manage_internal_datum(identifier: @se_id, data_type: 'publicationISSN', value: params[:internal_datum][:publication_issn])
      @pub_name = manage_internal_datum(identifier: @se_id, data_type: 'publicationName', value: params[:internal_datum][:publication_name])
      @msid = manage_internal_datum(identifier: @se_id, data_type: 'manuscriptNumber', value: params[:internal_datum][:msid])
      @doi = manage_internal_datum(identifier: @se_id, data_type: 'publicationDOI', value: params[:internal_datum][:doi])
    end

    def update_manuscript_metadata
      if !params[:internal_datum][:publication].blank? && params[:internal_datum][:publication_issn].blank?
        @error = 'Please select your journal from the autocomplete drop-down list'
        return
      end
      return if params[:internal_datum][:publication].blank? # keeps the default fill-in message
      my_url = "#{APP_CONFIG.old_dryad_url}/api/v1/organizations/#{CGI.escape(@pub_issn.value)}/manuscripts/#{CGI.escape(@msid.value)}"
      response = HTTParty.get(my_url,
                              query: { access_token: APP_CONFIG.old_dryad_access_token },
                              headers: { 'Content-Type' => 'application/json' })
      if response.code > 299
        @error = 'We could not find metadata to import for this manuscript. Please enter your metadata below.'
        return
      end
      dryad_import = Stash::Import::DryadManuscript.new(resource: @resource, httparty_response: response)
      dryad_import.populate
    rescue HTTParty::Error, SocketError => ex
      logger.error("Dryad manuscript API returned a HTTParty/Socket error for ISSN: #{@pub_issn.value}, MSID: #{@msid.value}\r\n #{ex}")
      @error = 'We could not find metadata to import for this manuscript. Please enter your metadata below.'
    end

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

p "********* data_type: #{data_type}, value: #{value}"

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
