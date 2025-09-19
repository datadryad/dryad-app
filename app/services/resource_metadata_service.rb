class ResourceMetadataService
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def recurate_awards
    resource.contributors.each do |contributor|
      next if contributor.award_number.blank? || contributor.api_integration_key.nil?

      AwardMetadataService.new(contributor).call
    end
    true
  end
end
