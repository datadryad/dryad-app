require 'httparty'
require 'stash/import/crossref'
require 'stash/import/dryad_manuscript'
require 'stash/link_out/pubmed_sequence_service'
require 'stash/link_out/pubmed_service'
require 'cgi'

# rubocop:disable Metrics/ClassLength
module StashDatacite
  class PublicationsController < ApplicationController
    def update
      @se_id = StashEngine::Identifier.find(params[:identifier_id])
      @resource = StashEngine::Resource.find(params[:resource_id])
      save_form_to_internal_data
      respond_to do |format|
        format.json do
          if params[:do_import] == 'true' || params[:do_import] == true
            @error = 'Please fill in the form completely' if params[:msid]&.strip.blank? && params[:primary_article_doi]&.strip.blank?
            update_manuscript_metadata if params[:import_type] == 'manuscript'
            update_doi_metadata if params[:primary_article_doi].present? && params[:import_type] == 'published'
            if !@doi&.related_identifier.blank? && params[:import_type] == 'published'
              manage_pubmed_datum(identifier: @se_id, doi: @doi.related_identifier)
            end
            render json: { error: @error, reloadPage: @error.blank? }
          else
            render json: { error: @error, reloadPage: false }
          end
        end
      end
    end

    # GET /publications/autocomplete?term={query_term}
    def autocomplete
      partial_term = params['term']
      if partial_term.blank?
        render json: nil
      else
        # clean the partial_term of unwanted characters so it doesn't cause errors
        partial_term.gsub!(%r{[/\-\\()~!@%&"\[\]\^:]}, ' ')

        matches = StashEngine::Journal.where('title like ?', "%#{partial_term}%").limit(40).to_a
        alt_matches = StashEngine::JournalTitle.where('show_in_autocomplete=true and title like ?', "%#{partial_term}%").limit(10)
        alt_matches.each do |am|
          matches << { title: am.title, issn: am.journal.issn }
        end
        render json: bubble_up_exact_matches(result_list: matches, term: partial_term)
      end
    end

    # GET /publications/issn/{id}
    def issn
      target_issn = params['id']
      return if target_issn.blank?
      return unless target_issn =~ /\d+-\w+/

      match = StashEngine::Journal.where(issn: target_issn).first
      render json: match
    end

    def save_form_to_internal_data
      @pub_name = params[:publication_name]
      @pub_issn = params[:publication_issn]
      if @pub_issn.blank?
        exact_matches = StashEngine::Journal.where(title: @pub_name)
        @pub_issn = exact_matches.first.issn if exact_matches.count == 1
      end
      fix_removable_asterisk
      @pub_name = manage_internal_datum(identifier: @se_id, data_type: 'publicationName', value: @pub_name)
      @pub_issn = manage_internal_datum(identifier: @se_id, data_type: 'publicationISSN', value: @pub_issn)

      if params[:msid].present?
        parsed_msid = parse_msid(issn: params[:publication_issn], msid: params[:msid])
        @msid = manage_internal_datum(identifier: @se_id, data_type: 'manuscriptNumber', value: parsed_msid)
      end

      # if the newly-set journal wants PPR by default, set the PPR value for this resource
      @resource.update(hold_for_peer_review: @se_id.journal&.default_to_ppr)

      save_doi
    end

    def save_doi
      form_doi = params[:primary_article_doi]
      return if form_doi.blank?

      bare_form_doi = Stash::Import::Crossref.bare_doi(doi_string: form_doi)
      related_dois = @resource.related_identifiers

      related_dois.each do |rd|
        bare_related_doi = Stash::Import::Crossref.bare_doi(doi_string: rd.related_identifier)
        return nil if bare_related_doi.include?(bare_form_doi) # user is entering a DOI that we already have
        next unless bare_form_doi.include? bare_related_doi

        standard_doi = RelatedIdentifier.standardize_doi(bare_form_doi)

        # user is expanding on a DOI that we already have; update it in the DB (and change the work_type if needed)
        rd.update(related_identifier: standard_doi, related_identifier_type: 'doi', work_type: 'primary_article',
                  hidden: false)
        rd.update(verified: rd.live_url_valid?) # do this separately since we need the doi in standard format in object to check
        return nil
      end

      # none of the existing related_dois overlap with the form_doi; add the form_doi as a completely new relation
      standard_doi = RelatedIdentifier.standardize_doi(bare_form_doi)
      ri = RelatedIdentifier.create(resource_id: @resource.id,
                                    related_identifier: standard_doi,
                                    related_identifier_type: 'doi',
                                    relation_type: 'iscitedby',
                                    work_type: 'primary_article',
                                    hidden: false)
      ri.update(verified: ri.live_url_valid?) # do this separately since we need the doi in standard format in object to check
      @resource.reload
    end

    # parse out the "relevant" part of the manuscript ID, ignoring the parts that the journal changes for different versions of the same item
    def parse_msid(issn:, msid:)
      logger.debug("Parsing msid #{msid} for journal #{issn}")
      regex = @se_id.journal&.manuscript_number_regex
      return msid if regex.blank?

      logger.debug("- found regex /#{regex}/")
      return msid if msid.match(regex).blank?

      logger.debug("- after regex applied: #{msid.match(regex)[1]}")
      result = msid.match(regex)[1]
      if result.present?
        result
      else
        msid
      end
    end

    def update_manuscript_metadata
      if !params[:publication].blank? && params[:publication_issn].blank?
        @error = 'Please select your journal from the autocomplete drop-down list'
        return
      end
      return if params[:publication].blank? # keeps the default fill-in message
      return if @pub_issn&.value.blank?
      return if @msid&.value.blank?

      journal = StashEngine::Journal.where(issn: @pub_issn.value).first
      if journal.blank?
        @error = 'Journal not recognized by Dryad'
        return
      end
      manu = StashEngine::Manuscript.where(journal: journal, manuscript_number: @msid.value).first
      if manu.blank?
        @error = 'We could not find metadata to import for this manuscript.'
        return
      end

      dryad_import = Stash::Import::DryadManuscript.new(resource: @resource, manuscript: manu)
      dryad_import.populate
    rescue HTTParty::Error, SocketError => e
      logger.error("Dryad manuscript API returned a HTTParty/Socket error for ISSN: #{@pub_issn.value}, MSID: #{@msid.value}\r\n #{e}")
      @error = 'We could not find metadata to import for this manuscript.'
    end

    def update_doi_metadata
      unless params[:primary_article_doi].present?
        @error = 'Please enter a DOI to import metadata'
        return
      end
      cr = Stash::Import::Crossref.query_by_doi(resource: @resource, doi: params[:primary_article_doi])
      unless cr.present?
        @error = "We couldn't obtain information from CrossRef about this DOI: #{params[:primary_article_doi]}"
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
      elsif value.present?
        datum = StashEngine::InternalDatum.create(stash_identifier: identifier, data_type: data_type, value: value)
      end
      datum
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

    private

    # Check whether the journal name ends with an asterisk that can be removed, because the journal name
    # exactly matches a name we have in the database
    def fix_removable_asterisk
      return unless @pub_name&.end_with?('*')

      journal = StashEngine::Journal.find_by_title(@pub_name)
      return unless journal.present?

      @pub_issn = journal.issn
      @pub_name = journal.title
    end

    # Re-order a journal list to prioritize exact matches at the beginning of the string, then
    # exact matches within the string, otherwise leaving the order unchanged
    def bubble_up_exact_matches(result_list:, term:)
      exact_match = []
      matches_at_beginning = []
      matches_within = []
      other_items = []
      match_term = term.downcase
      result_list.each do |result_item|
        name = result_item[:title].downcase
        if name == match_term
          exact_match << result_item
        elsif name.start_with?(match_term)
          matches_at_beginning << result_item
        elsif name.include?(match_term)
          matches_within << result_item
        else
          other_items << result_item
        end
      end
      exact_match + matches_at_beginning + matches_within + other_items
    end

  end
end
# rubocop:enable Metrics/ClassLength
