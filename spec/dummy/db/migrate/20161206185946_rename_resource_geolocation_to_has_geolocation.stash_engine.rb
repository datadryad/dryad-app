# This migration comes from stash_engine (originally 20160919230712)
class RenameResourceGeolocationToHasGeolocation < ActiveRecord::Migration
  def change
    change_table :stash_engine_resources do |t|
      t.rename :geolocation, :has_geolocation
    end
  end
end
