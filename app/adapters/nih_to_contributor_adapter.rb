class NIHToContributorAdapter < BaseContributorAdapter

  def award_number
    @response[:project_num]
  end

  def award_uri
    @response[:project_detail_url]
  end

  def award_title
    @response[:project_title]
  end

  def ic_fundings
    @response[:agency_ic_fundings]
  end

  private

  def main_ror_id
    NIH_ROR
  end

  def name_mappings
    NIH_ROR_NAMES_MAPPING
  end

  def response_contributor_name
    name = @response[:agency_ic_admin][:name]
    name&.downcase
  end
end
