module StashDatacite
  class GeolocationPlace < ActiveRecord::Base
    self.table_name = 'dcs_geo_location_places'
    belongs_to :resource, class_name: StashDatacite.resource_class

    after_save :set_geolocation_flag

    def set_geolocation_flag
      resource = StashDatacite.resource_class.where(id: resource_id).first
      return unless resource && resource.geolocation == false
      resource.geolocation = true
      resource.save!
    end

    #returns a bounding box string for use with Javascript
    def bounding_box_str
      return nil unless longitude && latitude
      "#{longitude} #{latitude} #{longitude} #{latitude}"
    end
  end
end
