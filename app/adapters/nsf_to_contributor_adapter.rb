class NSFToContributorAdapter < BaseContributorAdapter

  def award_number
    @response[:id]
  end

  def award_uri
    nil
  end

  def award_title
    @response[:title]
  end

  private

  def main_ror_id
    NSF_ROR
  end

  def response_contributor_name
    name = @response[:orgLongName2] || @response[:orgLongName]
    name&.downcase
  end
end
