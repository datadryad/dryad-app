class AwardMetadataService
  attr_reader :contributor, :api_integration_key

  def initialize(contributor)
    @contributor = contributor
    @api_integration_key = contributor.api_integration_key
  end

  def populate_from_api
    return if contributor.award_number.blank? || api_integration_key.nil?

    response = contributor.api_integration.new.search_award(contributor.award_number)
    return if response.empty?

    handle_response(response)
  end

  private

  def handle_response(response)
    data = adapter.new(response.first)

    attrs = {
      award_uri: data.award_uri,
      award_title: data.award_title
    }.merge(ic_attrs(data))
    pp "Updating contributor with ID: #{contributor.id} with #{attrs.inspect}" unless Rails.env.test?
    contributor.update attrs
  end

  def ic_attrs(data)
    return {} if data.ic_admin.blank? || data.ic_admin.downcase == contributor.contributor_name&.downcase

    ror = StashEngine::RorOrg.where(name: data.ic_admin).first
    return {} if ror.nil?

    {
      name_identifier_id: ror.ror_id,
      contributor_name: ror.name
    }
  end

  def adapter
    return nil if api_integration_key.nil?

    "#{api_integration_key}ToContributorAdapter".constantize
  end
end
