class CreateDcsEmbargoes < ActiveRecord::Migration
  def change
    create_table :dcs_embargoes do |t|
      t.column :embargo_type, "ENUM('none', 'download', 'description') DEFAULT 'none'"
      t.string :period
      t.date :start_date
      t.date :end_date
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
