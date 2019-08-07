require_dependency 'stash_datacite/application_controller'
require 'httparty'
require 'stash/import/crossref'
require 'stash/import/dryad_manuscript'
require 'stash/link_out/pubmed_sequence_service'
require 'stash/link_out/pubmed_service'
require 'cgi'

module StashDatacite
  # rubocop:disable Metrics/ClassLength
  class PublicationsController < ApplicationController
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def update
      @se_id = StashEngine::Identifier.find(params[:internal_datum][:identifier_id])
      save_form_to_internal_data
      respond_to do |format|
        format.js do
          if params[:internal_datum][:do_import] == 'true'
            @error = 'Please fill in the form completely' if params[:internal_datum][:msid].blank? && params[:internal_datum][:doi].blank?
            @resource = @se_id.latest_resource
            update_manuscript_metadata if params[:import_type] == 'manuscript'
            update_doi_metadata if !@doi&.related_identifier.blank? && params[:import_type] == 'published'
            manage_pubmed_datum(identifier: @se_id, doi: @doi.value) if !@doi&.value.blank? && params[:import_type] == 'published'
            params[:import_type] == 'published'
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
      @doi = manage_related_identifier(identifier: @se_id, related_identifier_type: 'doi', relation_type: 'issupplementto',
                                       value: params[:internal_datum][:doi])
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
      if @doi.related_identifier.blank?
        @error = 'Please enter a DOI to import metadata'
        return
      end
      cr = Stash::Import::Crossref.query_by_doi(resource: @resource, doi: @doi.related_identifier)
      unless cr.present?
        @error = "We couldn't obtain information from CrossRef about this DOI: #{@doi.related_identifier}"
        return
      end
      @resource = cr.populate_resource!
    rescue Serrano::NotFound, Serrano::BadGateway, Serrano::Error, Serrano::GatewayTimeout, Serrano::InternalServerError, Serrano::ServiceUnavailable
      @error = "We couldn't retrieve information from CrossRef about this DOI"
    end

    def manage_internal_datum(identifier:, data_type:, value:)
      datum = StashEngine::InternalDatum.where(stash_identifier: identifier, data_type: data_type).first
      if datum.present?
        datum.destroy unless value.present?
        datum.update(value: value) if value.present?
      else
        datum = StashEngine::InternalDatum.create(stash_identifier: identifier, data_type: data_type, value: value)
      end
      datum
    end

    def manage_related_identifier(identifier:, related_identifier_type:, relation_type:, value:)
      related_identifier = get_related_identifier(identifier: identifier, related_identifier_type: related_identifier_type,
                                                  relation_type: relation_type)
      if related_identifier.present?
        related_identifier.destroy unless value.present?
        related_identifier.update(related_identifier: value) if value.present?
      else
        related_identifier = StashDatacite::RelatedIdentifier.create(resource_id: @resource.id, relation_type: relation_type,
                                                                     related_identifier_type: related_identifier_type,
                                                                     related_identifier: value)
      end
      related_identifier
    end

    def manage_pubmed_datum(identifier:, doi:)
      pubmed_service = LinkOut::PubmedService.new
      pmid = pubmed_service.lookup_pubmed_id(doi)
      return unless pmid.present?

      internal_datum = StashEngine::InternalDatum.find_or_initialize_by(identifier_id: identifier.id, data_type: 'pubmedID')
      internal_datum.value = pmid.to_s
      return unless internal_datum.value_changed?

      internal_datum.save
      manage_genbank_datum(identifier: identifier, pmid: pmid)
    end

    def manage_genbank_datum(identifier:, pmid:)
      pubmed_sequence_service = LinkOut::PubmedSequenceService.new
      sequences = pubmed_sequence_service.lookup_genbank_sequences(pmid)
      return unless sequences.any?

      sequences.each do |k, v|
        external_ref = StashEngine::ExternalReference.find_or_initialize_by(identifier_id: identifier.id, source: k)
        external_ref.value = v.to_s
        next unless external_ref.value_changed?

        external_ref.save
      end
    end

    def get_related_identifier(identifier:, related_identifier_type:, relation_type:)
      return nil unless identifier.present?
      @resource = StashEngine::Identifier.find(identifier.is_a?(String) ? identifier : identifier.id).latest_resource
      return nil unless @resource.present? && related_identifier_type.present? && relation_type.present?
      StashDatacite::RelatedIdentifier.where(resource_id: @resource.id, relation_type: relation_type,
                                             related_identifier_type: related_identifier_type).first
    end

  end
  # rubocop:enable Metrics/ClassLength
end
