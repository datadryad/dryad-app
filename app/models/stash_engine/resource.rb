module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'

    after_save :set_geolocation_flag, on: [:create, :update]

    protected

    def set_geolocation_flag
      geolocation_places = StashDatacite::GeolocationPlace.where(resource_id: self.id)
      geolocation_points = StashDatacite::GeolocationPoint.where(resource_id: self.id)
      geolocation_boxes  = StashDatacite::GeolocationBox.where(resource_id: self.id)
      if (geolocation_places.exists? || geolocation_points.exists? || geolocation_boxes.exists?)
        self.geolocation = true
      end
    end
  end

end


  def set_geolocation_flag
    points = GeolocationPoint.where(resource_id: self.id)
    boxes  = GeolocationBox.where(resource_id: self.id)
    if (geolocation_places.exists? || geolocation_points.exists? || geolocation_boxes.exists?)
      self.geolocation = true
    end
  end