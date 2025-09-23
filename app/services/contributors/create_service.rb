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

    def create_funder_from_pubmed(pubmed_id, ror_id)
      award_numbers = Integrations::PubMed.new.fetch_awards_by_id(pubmed_id)
      award_numbers.each do |award_number|
        award_number = award_number.gsub(' ', '') if ror_id == NIH_ROR

        contributor = create(
          { contributor_type: 'funder', award_number: award_number, identifier_type: 'ror', name_identifier_id: ror_id }
        )
        AwardMetadataService.new(contributor).populate_from_api
      end
    end
  end
end
