class CreateStashEngineInstitutions < ActiveRecord::Migration
  def change
    create_table :stash_engine_institutions do |t|
      t.string :abbreviation
      t.string :short_name
      t.string :long_name
      t.string :landing_page
      t.string :external_id_strip
      t.string :campus
      t.string :logo
      t.string :url
      t.string :url_text
      t.string :shib_entity_id
      t.string :shib_entity_domain

      t.timestamps null: false
    end
  end
end
