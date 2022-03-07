class CreateDcsNameIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_name_identifiers do |t|
      t.string :name_identifier
      t.string :name_identifier_scheme
      t.text   :scheme_URI

      t.timestamps null: false
    end
  end
end
