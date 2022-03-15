class CreateDcsSizes < ActiveRecord::Migration[4.2]
  def change
    create_table :dcs_sizes do |t|
      t.string :size
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
