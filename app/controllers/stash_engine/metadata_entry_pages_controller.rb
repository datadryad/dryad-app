require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    # GET/POST/PUT  /generals/find_or_create
    def find_or_create
      find_resource
      set_instances
      set_title
      set_description
      set_geolocations
      set_relations
    end

    private

    def find_resource
      @resource = Resource.find(params[:resource_id].to_i) unless params[:resource_id].blank?
    end

    def set_resources
      @resources = StashDatacite.resource_class.constantize.all
    end

    def set_title
      @title = StashDatacite::Title.where(resource_id: @resource.id).first_or_initialize
    end

    def set_instances
      @contributor = StashDatacite::Contributor.where(resource_id: @resource.id).first_or_initialize
      @subject = StashDatacite::Subject.where(resource_id: @resource.id).first_or_initialize
      @resource_type = StashDatacite::ResourceType.where(resource_id: @resource.id).first_or_initialize
    end

    def set_description
      @abstract = StashDatacite::Description.type_abstract.find_or_create_by(resource_id: @resource.id)
      @methods = StashDatacite::Description.type_methods.find_or_create_by(resource_id: @resource.id)
      @usage_notes = StashDatacite::Description.type_usage_notes.find_or_create_by(resource_id: @resource.id)
    end

    def set_relations
      @related_identifier = StashDatacite::RelatedIdentifier.where(resource_id: @resource.id).first_or_initialize
      @relation_types = StashDatacite::RelationType.all
      @related_identifier_types = StashDatacite::RelatedIdentifierType.all
    end

    def set_geolocations
      @geolocation_point = StashDatacite::GeolocationPoint.where(resource_id: @resource.id).first_or_initialize
      @geolocation_box = StashDatacite::GeolocationBox.where(resource_id: @resource.id).first_or_initialize
      @geolocation_place = StashDatacite::GeolocationPlace.where(resource_id: @resource.id).first_or_initialize
    end
  end
end
