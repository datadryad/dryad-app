class CreateDcsAffliations < ActiveRecord::Migration
  def change
    create_table :dcs_affliations do |t|
      t.string :short_name
      t.string :long_name
      t.string :abbreviation
      t.string :campus
      t.string :logo
      t.string :url
      t.text   :url_text

      t.timestamps null: false
    end
  end
end
