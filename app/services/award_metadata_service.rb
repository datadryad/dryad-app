class AwardMetadataService
  attr_reader :contributor, :api_integration_key

  def initialize(contributor)
    @contributor = contributor
    @api_integration_key = contributor.api_integration_key
  end

  def populate_from_api
    response = fetch_api_data
    return if response.empty?

    handle_response(response)
  end

  def award_details
    response = fetch_api_data
    return if response.empty?

    data = adapter.new(response.first)
    ic_data = ic_attrs(data) || { name_identifier_id: nil, contributor_name: nil }

    {
      award_number: data.award_number,
      award_uri: data.award_uri,
      award_title: data.award_title
    }.merge(ic_data)
  end

  private

  def fetch_api_data
    return [] if contributor.award_number.blank? || api_integration_key.nil?

    contributor.api_integration.new.search_award(contributor.award_number)
  end

  def handle_response(response)
    data = adapter.new(response.first, contributor_id: contributor.id)

    attrs = {
      award_uri: data.award_uri,
      award_title: data.award_title
    }.merge(ic_attrs(data))
    pp "Updating contributor with ID: #{contributor.id} with #{attrs.inspect}" unless Rails.env.test?
    contributor.update attrs
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
