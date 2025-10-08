class NIHToContributorAdapter

  def initialize(response = {})
    response ||= {}
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

  def ic_admin_name
    ror.try('contributor_name')
  end

  def ic_admin_identifier
    ror.try('name_identifier_id')
  end

  def ic_fundings
    @response[:agency_ic_fundings]
  end

  def ror
    return {} if @response[:agency_ic_admin][:name].blank?

    contributors_hash[@response[:agency_ic_admin][:name]]
  end

  def contributors_hash
    related_contributors = StashDatacite::ContributorGrouping.find_by(name_identifier_id: NIH_ROR)&.json_contains
    related_contributors.to_h do |contributor|
      [contributor['contributor_name'], contributor]
    end
  end
end
