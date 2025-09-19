class NIHToContributorAdapter

  def initialize(response)
    @response = response.with_indifferent_access
  end

  def award_number
    @response[:project_num]
  end

  def award_uri
    @response[:project_detail_url]
  end

  def award_title
    @response[:project_title]
  end

  def ic_admin
    @response[:agency_ic_admin][:name]
  end

  def ic_fundings
    @response[:agency_ic_fundings]
  end
end
