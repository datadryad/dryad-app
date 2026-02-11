module Contributors
  class CreateService
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    def create(attrs)
      contributor = resource.contributors.find_or_create_by(attrs)

      # delete the default funder created from UI
      if !contributor.new_record? && contributor.funder? && resource.funders.count == 2 && resource.funders.where(name_identifier_id: '0').exists?
        resource.funders.where(name_identifier_id: '0').destroy_all
      end

      contributor
    end

    def create_funder_from_pubmed(ror_id)
      if pubmed_ids.any?
        pubmed_ids.each do |pmid|
          create_with_pubmed_id(pmid, ror_id)
        end
      else
        create_from_primary_article(ror_id)
      end
    end

    private

    def pubmed_ids
      @pubmed_ids ||= resource.identifier.internal_data.where(data_type: 'pubmedID').pluck(:value)
    end

    def create_with_pubmed_id(pubmed_id, ror_id)
      award_numbers = Integrations::PubMed.new.fetch_awards_by_id(pubmed_id)
      award_numbers.each do |award_number|
        award_number = award_number.gsub(' ', '') if ror_id == NIH_ROR

        contributor = create(
          { contributor_type: 'funder', award_number: award_number, identifier_type: 'ror', name_identifier_id: ror_id }
        )
        AwardMetadataService.new(contributor).populate_from_api
      end
    end

    def create_from_primary_article(ror_id)
      # check for primary_article
      articles = resource.related_identifiers.primary_article.where(related_identifier_type: 'doi')
      return unless articles.any?

      articles.each do |article|
        doi  = Integrations::Crossref.bare_doi(doi_string: article.related_identifier)
        pmid = Integrations::PubMed.new.pmid_by_primary_article(doi)
        next if pmid.blank?

        # add PubMed ID to the database
        resource.identifier.internal_data.where(data_type: 'pubmedID').find_or_create_by(value: pmid)
        create_with_pubmed_id(pmid, ror_id)
      end
    end
  end
end
