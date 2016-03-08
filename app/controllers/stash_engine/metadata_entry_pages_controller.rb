require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    before_action :require_login
    # GET/POST/PUT  /generals/find_or_create
    def find_or_create
      # find_resource
      # set_instances
      # set_title
      # set_description
      # set_geolocations
      # set_relations
      # set_creators
      # set_subjects
    end

    def metadata_callback
      auth_hash = request.env['omniauth.auth']
      params = request.env['omniauth.params']
      path = request.env['omniauth.origin']
      current_user = StashEngine::User.find(params['current_user_id'])
      creator = metadata_engine::Creator.new( resource_id: params['resource_id'],
                                              creator_first_name: auth_hash.info.first_name,
                                              creator_last_name: auth_hash.info.last_name,
                                              orcid_id: auth_hash.uid)
      creator.save
      if creator.creator_first_name.downcase == current_user.first_name.downcase && creator.creator_last_name.downcase == current_user.last_name.downcase
        current_user.orcid = true
        current_user.save
      end
      redirect_to "#{request.env['omniauth.origin']}"
    end

    private

    # def find_resource
    #   @resource = Resource.find(params[:resource_id].to_i) unless params[:resource_id].blank?
    # end

    # def set_resources
    #   @resources = StashDatacite.resource_class.constantize.all
    # end

    # def set_creators
    #   @creators = metadata_engine::Creator.where(resource_id: @resource.id)
    #   @creator = metadata_engine::Creator.new(resource_id: @resource.id)
    # end

    # def set_title
    #   @title = metadata_engine::Title.where(resource_id: @resource.id).first_or_initialize
    # end

    # def set_subjects
    #   @subject = metadata_engine::Subject.new
    #   @subjects = @resource.subjects
    # end

    # def set_instances
    #   @contributors = metadata_engine::Contributor.where(resource_id: @resource.id)
    #   @contributor = metadata_engine::Contributor.new(resource_id: @resource.id)
    #   @resource_type = metadata_engine::ResourceType.where(resource_id: @resource.id).first_or_initialize
    # end

    # def set_description
    #   @abstract = metadata_engine::Description.type_abstract.find_or_create_by(resource_id: @resource.id)
    #   @methods = metadata_engine::Description.type_methods.find_or_create_by(resource_id: @resource.id)
    #   @usage_notes = metadata_engine::Description.type_usage_notes.find_or_create_by(resource_id: @resource.id)
    # end

    # def set_relations
    #   @related_identifiers = metadata_engine::RelatedIdentifier.where(resource_id: @resource.id)
    #   @related_identifier = metadata_engine::RelatedIdentifier.new(resource_id: @resource.id)
    # end

    # def set_geolocations
    #   @geolocation_point = metadata_engine::GeolocationPoint.new(resource_id: @resource.id)
    #   @geolocation_points = metadata_engine::GeolocationPoint.where(resource_id: @resource.id)
    #   @geolocation_box = metadata_engine::GeolocationBox.new(resource_id: @resource.id)
    #   @geolocation_boxes = metadata_engine::GeolocationBox.where(resource_id: @resource.id)
    #   @geolocation_place = metadata_engine::GeolocationPlace.new(resource_id: @resource.id)
    #   @geolocation_places = metadata_engine::GeolocationPlace.where(resource_id: @resource.id)
    # end
  end
end
