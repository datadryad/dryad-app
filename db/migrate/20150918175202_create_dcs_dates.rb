class CreateDcsDates < ActiveRecord::Migration
  def change
    create_table :dcs_dates do |t|
      t.date :date
      t.column :date_type, :integer, default: 0
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
