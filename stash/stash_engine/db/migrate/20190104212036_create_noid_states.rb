class CreateNoidStates < ActiveRecord::Migration
  def change
    create_table :noid_states do |t|
      t.text :state
      t.timestamps
    end
  end
end
