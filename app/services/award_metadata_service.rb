class AwardMetadataService
  attr_reader :contributor, :api_integration_key, :api_integration, :award_number

  def initialize(contributor, api_integration_key: nil, api_integration: nil, award_number: nil)
    @contributor = contributor
    @api_integration_key = api_integration_key || contributor.api_integration_key
    @api_integration = api_integration || contributor.api_integration
    @award_number = award_number || contributor.award_number
  end

  def populate_from_api
    return unless contributor.auto_update?

    response = fetch_api_data
    return if response.blank?

    handle_response(response.first)
  end

  def award_details
    response = fetch_api_data
    return if response.blank?

    parse_response(response.first)
  end

  def search
    response = fetch_api_data
    return [] if response.blank?

    response.map { |item| parse_response(item) }
  end

  private

  def fetch_api_data
    return [] if award_number.blank? || api_integration_key.nil?

    api_integration.new.search_award(award_number)
  end

  def handle_response(response)
    attrs = parse_response(response)
    pp "Updating contributor with ID: #{contributor.id} and award ID: #{contributor.award_number} with #{attrs.inspect}" unless Rails.env.test?
    contributor.update attrs
  end

  def parse_response(response)
    data = adapter.new(response, contributor_id: contributor.id)
    {
      award_number: data.award_number,
      award_uri: data.award_uri,
      award_title: data.award_title
    }.merge(ic_attrs(data))
  end

  def ic_attrs(data)
    return {} if data.ic_admin_identifier.blank? || data.ic_admin_name.blank? || data.ic_admin_name.downcase == contributor.contributor_name&.downcase

    {
      name_identifier_id: data.ic_admin_identifier,
      contributor_name: data.ic_admin_name
    }
  end

  def adapter
    return nil if api_integration_key.nil?

    "#{api_integration_key}ToContributorAdapter".constantize
  end
end
