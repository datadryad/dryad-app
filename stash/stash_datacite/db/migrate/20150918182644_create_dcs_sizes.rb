class CreateDcsSizes < ActiveRecord::Migration
  def change
    create_table :dcs_sizes do |t|
      t.string :size
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
