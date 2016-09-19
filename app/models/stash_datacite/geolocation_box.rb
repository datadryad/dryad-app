module StashDatacite
  class GeolocationBox < ActiveRecord::Base
    self.table_name = 'dcs_geo_location_boxes'
    has_one :geolocation, class_name: 'StashDatacite::Geolocation', foreign_key: 'box_id', dependent: :nullify

    def set_geolocation_flag
      resource = StashDatacite.resource_class.where(id: resource_id).first
      return unless resource && resource.geolocation == false
      resource.geolocation = true
      resource.save!
    end

    #returns a bounding box string for use with Javascript
    def bounding_box_str
      return nil unless sw_longitude && sw_latitude && ne_longitude && ne_latitude
      "#{sw_longitude} #{sw_latitude} #{ne_longitude} #{ne_latitude}"
    end
  end
end
