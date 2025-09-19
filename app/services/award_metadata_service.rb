class AwardMetadataService
  attr_reader :contributor, :api_integration_key

  def initialize(contributor)
    @contributor = contributor
    @api_integration_key = contributor.api_integration_key
  end

  def call
    return if contributor.award_number.nil? || api_integration_key.nil?

    response = contributor.api_integration.new.search_award(contributor.award_number)
    handle_response(response)
  end

  private

  def handle_response(response)
    data = adapter.new(response.first)

    contributor.update(
      award_uri: data.award_uri,
      award_title: data.award_title
    )
  end

  def adapter
    return nil if api_integration_key.nil?

    "#{api_integration_key}ToContributorAdapter".constantize
  end
end
