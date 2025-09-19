class NSFToContributorAdapter

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
    @response[:title]
  end
end
