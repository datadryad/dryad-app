# This migration comes from stash_datacite (originally 20150918173831)
class CreateDcsNameIdentifiers < ActiveRecord::Migration
  def change
    create_table :dcs_name_identifiers do |t|
      t.string :name_identifier
      t.string :name_identifier_scheme
      t.text   :scheme_URI

      t.timestamps null: false
    end
  end
end
