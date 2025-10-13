class NIHToContributorAdapter

  def initialize(response = {}, contributor_id: nil)
    response ||= {}
    @response = response.with_indifferent_access
    @contributor_id = contributor_id
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
    ror['contributor_name']
  end

  def ic_admin_identifier
    ror['name_identifier_id']
  end

  def ic_fundings
    @response[:agency_ic_fundings]
  end

  def ror
    return @ror if @ror
    return @ror = {} if @response[:agency_ic_admin][:name].blank?

    contributor_name = @response[:agency_ic_admin][:name].downcase

    # first we check name mapping
    ror_id = NIH_ROR_NAMES_MAPPING[contributor_name]
    # if there is a match
    if ror_id.present?
      # check database NIH children list for an uptodate name
      children = contributors_hash_by(key: 'name_identifier_id')
      return @ror = children[ror_id] if children[ror_id]
    end

    # if no match, check the database NIH children list by contributor name
    children = contributors_hash_by(key: 'contributor_name')
    @ror = children[contributor_name]
    return @ror if @ror.present?

    # alert devs of missing rr info in NIH children list
    StashEngine::NotificationsMailer.nih_child_missing(@contributor_id, @response).deliver_now
    # do not update ROR information
    @ror = {}
  end

  def contributors_hash_by(key:)
    related_contributors = StashDatacite::ContributorGrouping.find_by(name_identifier_id: NIH_ROR)&.json_contains
    related_contributors.to_h do |contributor|
      [contributor[key], contributor]
    end
  end
end
