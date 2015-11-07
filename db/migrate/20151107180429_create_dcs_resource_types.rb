class CreateDcsResourceTypes < ActiveRecord::Migration
  def change
    create_table :dcs_resource_types do |t|
      t.string :resource_type
      t.column :resource_type_general, :integer, default: 0
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
