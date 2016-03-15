require_dependency "stash_datacite/application_controller"

module StashDatacite
  class MetadataEntryPagesController < ApplicationController
    before_action :find_resource

    def find_or_create
      set_resource_type
      set_title
      set_creators
      set_descriptions
      set_contributors
      set_subjects
      set_relations
      set_geolocations
      respond_to do |format|
        format.js
        #format.html
      end
    end

    private

    def find_resource
      @resource = StashDatacite.resource_class.find(params[:resource_id].to_i) unless params[:resource_id].blank?
    end

    def set_creators
      @creators = Creator.where(resource_id: @resource.id)
      @creator = Creator.new(resource_id: @resource.id)
    end

    def set_title
      @title = Title.where(resource_id: @resource.id).first_or_initialize
    end

    def set_subjects
      @subject = Subject.new
      @subjects = @resource.subjects
    end

    def set_resource_type
      @resource_type = ResourceType.where(resource_id: @resource.id).first_or_initialize
    end

    def set_contributors
      @contributors = Contributor.where(resource_id: @resource.id)
      @contributor = Contributor.new(resource_id: @resource.id)
    end

    def set_descriptions
      @abstract = Description.type_abstract.find_or_create_by(resource_id: @resource.id)
      @methods = Description.type_methods.find_or_create_by(resource_id: @resource.id)
      @usage_notes = Description.type_usage_notes.find_or_create_by(resource_id: @resource.id)
    end

    def set_relations
      @related_identifiers = RelatedIdentifier.where(resource_id: @resource.id)
      @related_identifier = RelatedIdentifier.new(resource_id: @resource.id)
    end

    def set_geolocations
      @geolocation_point = GeolocationPoint.new(resource_id: @resource.id)
      @geolocation_points = GeolocationPoint.where(resource_id: @resource.id)
      @geolocation_box = GeolocationBox.new(resource_id: @resource.id)
      @geolocation_boxes = GeolocationBox.where(resource_id: @resource.id)
      @geolocation_place = GeolocationPlace.new(resource_id: @resource.id)
      @geolocation_places = GeolocationPlace.where(resource_id: @resource.id)
    end
  end
end
