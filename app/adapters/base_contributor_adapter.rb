class BaseContributorAdapter

  def initialize(response = {}, contributor_id: nil)
    response ||= {}
    @response = response.with_indifferent_access
    @contributor_id = contributor_id
  end

  def ic_admin_name
    ror[:contributor_name]
  end

  def ic_admin_identifier
    ror[:name_identifier_id]
  end

  private

  def name_mappings
    NSF_ROR_NAMES_MAPPING
  end

  def ror
    return @ror if @ror
    return @ror = {} if response_contributor_name.blank?

    # first we check name mapping
    ror_id = name_mappings[response_contributor_name]
    # if there is a match
    if ror_id.present?
      # check database children list for an up to date name
      children = contributors_hash_by(key: :name_identifier_id)
      return @ror = children[ror_id] if children[ror_id]
    end

    # if no match, check the database children list by contributor name
    children = contributors_hash_by(key: :contributor_name)
    @ror = children[response_contributor_name]
    return @ror if @ror.present?

    # alert devs of missing info in children list
    StashEngine::NotificationsMailer.nih_child_missing(@contributor_id, @response).deliver_now
    # do not update ROR information
    @ror = {}
  end

  def contributors_hash_by(key:)
    related_contributors = StashDatacite::Contributor.related_rors_with_name(main_ror_id)
    related_contributors.to_h do |contributor|
      [contributor[key].downcase, contributor]
    end
  end
end
