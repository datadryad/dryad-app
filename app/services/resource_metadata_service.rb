class ResourceMetadataService
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def recurate_awards
    resource.funders.each do |funder|
      next if funder.award_number.blank? || funder.api_integration_key.nil?

      AwardMetadataService.new(funder).populate_from_api
    end
    true
  end
end
