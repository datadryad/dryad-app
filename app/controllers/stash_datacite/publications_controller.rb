require 'httparty'
require 'stash/import/crossref'
require 'stash/import/dryad_manuscript'
require 'stash/link_out/pubmed_sequence_service'
require 'stash/link_out/pubmed_service'
require 'cgi'

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength
module StashDatacite
  class PublicationsController < ApplicationController
    def update
      @resource = StashEngine::Resource.find(params[:resource_id])
      @se_id = @resource.identifier
      save_publications
      respond_to do |format|
        format.json do
          if ['true', true].include?(params[:do_import])
            @se_id.update(import_info: params[:import_type])
            @error = 'Please fill in the form completely' if params[:msid]&.strip.blank? && params[:primary_article_doi]&.strip.blank?
            update_manuscript_metadata if params[:import_type] == 'manuscript'
            update_doi_metadata if params[:primary_article_doi].present? && params[:import_type] != 'manuscript'
            if !@doi&.related_identifier.blank? && params[:import_type] == 'published'
              manage_pubmed_datum(identifier: @se_id, doi: @doi.related_identifier)
            end
            @resource.reload
            import_data = {
              title: @resource.title,
              authors: @resource.authors.as_json(include: [:affiliations]),
              descriptions: @resource.descriptions,
              subjects: @resource.subjects,
              contributors: @resource.contributors,
              resource_preprint: @resource.resource_preprint
            }
            render json: {
              error: @error,
              journal: @resource.journal,
              resource_publication: @resource.resource_publication,
              related_identifiers: @resource.related_identifiers,
              import_data: @error ? false : import_data
            }
          else
            render json: { error: @error, journal: @resource.journal, import_data: false, resource_publication: @resource.resource_publication,
                           related_identifiers: @resource.related_identifiers }
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # GET /publications/autocomplete?term={query_term}
    def autocomplete
      partial_term = params[:term]
      if partial_term.blank?
        render json: nil
      else
        # clean the partial_term of unwanted characters so it doesn't cause errors
        partial_term.gsub!(%r{[/\-\\()~!@%&"\[\]\^:]}, ' ')
        found = params.key?(:preprint) ? StashEngine::Journal.servers : StashEngine::Journal
        found = found.where('title like ?', "%#{partial_term}%").includes([:issns]).limit(40).to_a
        matches = found.map { |m| { id: m.id, title: m.title, issn: m.single_issn } }
        alt_matches = StashEngine::JournalTitle.where('show_in_autocomplete=true and title like ?', "%#{partial_term}%").limit(10)
        alt_matches.each do |am|
          matches << { id: am.journal.id, title: am.title, issn: am.journal.single_issn }
        end
        render json: bubble_up_exact_matches(result_list: matches.uniq { |j| j[:id] }, term: partial_term)
      end
    end

    # GET /publications/automsid?term={query_term}
    def automsid
      partial_term = params[:term]
      render json: nil and return if partial_term.blank?

      # clean the partial_term of unwanted characters so it doesn't cause errors
      partial_term.gsub!(/~!@%&"/, '')
      found = StashEngine::Manuscript.where(journal_id: params[:jid]).where('manuscript_number like ?', "%#{partial_term}%").limit(40).to_a
      matches = found.map { |m| { id: m.manuscript_number, title: m.metadata['ms title'], authors: m.metadata['ms authors'].take(3) } }
      render json: matches
    end

    # GET /publications/api_list
    def api_list
      @api_journals = StashEngine::User.joins('inner join oauth_applications on owner_id = stash_engine_users.id')
        .joins(:roles).where(roles: { role_object_type: ['StashEngine::Journal', 'StashEngine::JournalOrganization'] })
        .distinct.map(&:journals_as_admin).flatten.uniq.map(&:issn_array).flatten.uniq
      render json: { api_journals: @api_journals }
    end

    # GET /publications/issn/{id}
    def issn
      target_issn = params['id']
      return if target_issn.blank?
      return unless target_issn =~ /\d+-\w+/

      match = StashEngine::Journal.find_by_issn(target_issn)
      render json: match
    end

    def save_publications
      @pub_name = params[:publication_name]
      @pub_issn = params[:publication_issn]
      @msid = params[:msid].present? ? parse_msid(issn: params[:publication_issn], msid: params[:msid]) : nil
      if params[:primary_article_doi].blank?
        @resource.related_identifiers.where(work_type: params[:import_type] == 'preprint' ? 'preprint' : 'primary_article').destroy_all
      end
      if @pub_issn.blank? && @pub_name.present?
        exact_matches = StashEngine::Journal.find_by_title(@pub_name)
        @pub_issn = exact_matches.single_issn if exact_matches.present?
      end
      begin
        publication = StashEngine::ResourcePublication
          .find_or_create_by(resource_id: @resource.id, pub_type: params[:import_type] == 'preprint' ? :preprint : :primary_article)
        publication.publication_name = @pub_name
        publication.publication_issn = @pub_issn
        publication.manuscript_number = @msid
        publication.save
      rescue ActiveRecord::RecordNotUnique
        publication = StashEngine::ResourcePublication.find_by(resource_id: @resource.id)
        publication.update(publication_name: @pub_name, publication_issn: @pub_issn, manuscript_number: @msid)
      end
      @resource.reload

      if @resource.identifier.allow_review? && @resource.identifier.date_last_curated.blank? && @resource.journal&.default_to_ppr?
        # if the newly-set journal wants PPR by default, and it is allowed, set the PPR value for this resource
        @resource.update(hold_for_peer_review: true)
      end

      save_doi
    end
    # rubocop:enable Metrics/AbcSize

    def save_doi
      form_doi = params[:primary_article_doi]
      return if form_doi.blank?

      work_type = params[:import_type] == 'preprint' ? 'preprint' : 'primary_article'
      bare_form_doi = Stash::Import::Crossref.bare_doi(doi_string: form_doi)
      related_dois = @resource.related_identifiers

      related_dois.each do |rd|
        bare_related_doi = Stash::Import::Crossref.bare_doi(doi_string: rd.related_identifier)
        next unless bare_form_doi.include?(bare_related_doi) || bare_related_doi.include?(bare_form_doi) # user is entering a DOI that we already have

        standard_doi = RelatedIdentifier.standardize_doi(bare_form_doi)
        # user is expanding on a DOI that we already have; update it in the DB (and change the work_type if needed)
        rd.update(related_identifier: standard_doi, related_identifier_type: 'doi', work_type: work_type)
        rd.update(verified: rd.live_url_valid?, hidden: false) # do this separately since we need the doi in standard format in object to check
        return nil
      end

      # none of the existing related_dois overlap with the form_doi; add the form_doi as a completely new relation
      standard_doi = RelatedIdentifier.standardize_doi(bare_form_doi)
      existing_primary = @resource.related_identifiers.where(work_type: work_type).first
      hsh = { related_identifier: standard_doi,
              related_identifier_type: 'doi',
              relation_type: 'iscitedby',
              work_type: work_type,
              hidden: false }

      ri = if existing_primary.present?
             existing_primary.update(hsh)
             existing_primary
           else
             RelatedIdentifier.create(hsh.merge(resource_id: @resource.id))
           end

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
      if @pub_name.blank? && @pub_issn.blank?
        @error = 'Please select your journal from the autocomplete list.'
        return
      end
      if @msid.blank?
        @error = 'Please enter your manuscript number.'
        return
      end
      if @pub_issn.blank?
        @error = 'Journal not integrated with Dryad. Please fill in your title manually.'
        return
      end
      journal = StashEngine::Journal.find_by_issn(@pub_issn)
      if journal.blank?
        @error = 'Journal not integrated with Dryad. Please fill in your title manually.'
        return
      end
      manu = StashEngine::Manuscript.where(journal: journal, manuscript_number: @msid).last
      if manu.blank?
        @error = 'We could not find metadata to import for this manuscript. Please fill in your title manually.'
        return
      end
      dryad_import = Stash::Import::DryadManuscript.new(resource: @resource, manuscript: manu)
      dryad_import.populate
    rescue HTTParty::Error, SocketError => e
      logger.error("Dryad manuscript API returned a HTTParty/Socket error for ISSN: #{@pub_issn}, MSID: #{@msid}\r\n #{e}")
      @error = 'We could not find metadata to import for this manuscript. Please fill in your title manually.'
    end

    def update_doi_metadata
      unless params[:primary_article_doi].present?
        @error = 'Please enter a DOI to import metadata'
        return
      end
      cr = Stash::Import::Crossref.query_by_doi(resource: @resource, doi: params[:primary_article_doi])
      unless cr.present?
        @error = "We couldn't find metadata to import for this DOI. Please fill in your title manually."
        return
      end

      work_type = params[:import_type] == 'preprint' ? 'preprint' : 'primary_article'
      @resource = @resource.previous_curated_resource.present? ? cr.populate_pub_update!(work_type) : cr.populate_resource!(work_type)
    rescue Serrano::NotFound, Serrano::BadGateway, Serrano::Error, Serrano::GatewayTimeout, Serrano::InternalServerError, Serrano::ServiceUnavailable
      @error = "We couldn't find metadata to import for this DOI. Please fill in your title manually."
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
