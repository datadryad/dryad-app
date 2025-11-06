class NSFToContributorAdapter

  def initialize(response = {}, contributor_id: nil)
    response ||= {}
    @response = response.with_indifferent_access
    @contributor_id = contributor_id
  end

  def award_number
    @response[:id]
  end

  def award_uri
    nil
  end

  def award_title
    @response[:title]
  end

  def ic_admin_name
    StashEngine::RorOrg.find_by(ror_id: NSF_ROR)&.name
  end

  def ic_admin_identifier
    NSF_ROR
  end
end
