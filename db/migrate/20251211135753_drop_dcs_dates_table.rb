class DropDcsDatesTable < ActiveRecord::Migration[8.0]
  def up
    remove_index :dcs_dates, :resource_id
    drop_table :dcs_dates
  end

  def down
    create_table :dcs_dates do |t|
      t.date :date
      t.column :date_type, "ENUM('accepted', 'available', 'copyrighted', 'collected', 'created',
                                  'issued', 'submitted', 'updated', 'valid', 'withdrawn') DEFAULT NULL"
      t.integer :resource_id

      t.timestamps null: false
    end
    add_index :dcs_dates, :resource_id
  end
end
