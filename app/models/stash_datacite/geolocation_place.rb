module StashDatacite
  class GeolocationPlace < ActiveRecord::Base
    self.table_name = "dcs_geo_location_places"
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
  end
end
