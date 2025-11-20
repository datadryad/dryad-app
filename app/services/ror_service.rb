class RorService
  attr_reader :ror

  def initialize(ror_id)
    @ror = StashEngine::RorOrg.find_by(ror_id: ror_id)
  end

  def withdrawn(successor)
    return if successor.blank?

    successor_ror = StashEngine::RorOrg.find_by(ror_id: successor['id'])
    return if successor_ror.blank?

    ror.contributors.each { |a| a.update(name_identifier_id: successor['id'], contributor_name: successor_ror['label']) }
    ror.affiliations.each { |a| a.update(ror_id: successor['id'], long_name: successor['label']) }
    ror.funders.each { |a| a.update(ror_id: successor['id'], name: successor['label']) }
    ror.tenant_ror_orgs.each { |a| a.update(ror_id: successor['id']) }
  end
end
