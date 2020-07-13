class RenameResourceGeolocationToHasGeolocation < ActiveRecord::Migration[4.2]
  def change
    change_table :stash_engine_resources do |t|
      t.rename :geolocation, :has_geolocation
    end
  end
end
