class NSFToContributorAdapter

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
    @response[:title]
  end

  def ic_admin_name; end
  def ic_admin_identifier; end
end
