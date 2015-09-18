class CreateDcsTitles < ActiveRecord::Migration
  def change
    create_table :dcs_titles do |t|
      t.string :title
      t.column :title_type, :integer, default: 0
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
