module StashDatacite
  class GeolocationBox < ActiveRecord::Base
    self.table_name = 'dcs_geo_location_boxes'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    after_save :set_geolocation_flag

    def set_geolocation_flag
      resource = StashDatacite.resource_class.constantize.where(id: resource_id).first
      return unless resource && resource.geolocation == false
      resource.geolocation = true
      resource.save!
    end
  end
end
