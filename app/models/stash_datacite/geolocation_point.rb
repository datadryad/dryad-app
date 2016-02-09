module StashDatacite
  class GeolocationPoint < ActiveRecord::Base
    self.table_name = 'dcs_geo_location_points'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    after_save :set_geolocation_flag, on: [:create, :update]

    def set_geolocation_flag
      resource = StashDatacite.resource_class.constantize.where(id: resource_id).first
      resource.geolocation = true if resource.geolocation == false
    end
  end
end
