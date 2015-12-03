require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    # GET/POST/PUT  /generals/find_or_create
    def find_or_create
      @resource = Resource.find(params[:resource_id].to_i) unless params[:resource_id].blank?
      @relation_types = StashDatacite::RelationType.all
      @related_identifier_types = StashDatacite::RelatedIdentifierType.all
      set_instances
    end

    private

    def generals_params
      params.require(:general).permit(:resource_id)
    end

    def set_resources
      @resources = StashDatacite.resource_class.constantize.all
    end

    def set_instances
      @creator = StashDatacite::Creator.where(resource_id: @resource.id).first_or_initialize
      @title = StashDatacite::Title.where(resource_id: @resource.id).first_or_initialize
      @description = StashDatacite::Description.where(resource_id: @resource.id).first_or_initialize
      @contributor = StashDatacite::Contributor.where(resource_id: @resource.id).first_or_initialize
      @subject = StashDatacite::Subject.where(resource_id: @resource.id).first_or_initialize
      @resource_type = StashDatacite::ResourceType.where(resource_id: @resource.id).first_or_initialize
      @related_identifier = StashDatacite::RelatedIdentifier.where(resource_id: @resource.id).first_or_initialize
      @geolocation_point = StashDatacite::GeolocationPoint.where(resource_id: @resource.id).first_or_initialize
      @geolocation_box = StashDatacite::GeolocationBox.where(resource_id: @resource.id).first_or_initialize
      @geolocation_place = StashDatacite::GeolocationPlace.where(resource_id: @resource.id).first_or_initialize
    end
  end
end
