class CreateDcsRelationTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_relation_types do |t|
      t.string :relation_type
      t.string :related_metadata_scheme
      t.text   :scheme_URI
      t.string :scheme_type

      t.timestamps null: false
    end
  end
end
