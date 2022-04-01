class CreateNoidStates < ActiveRecord::Migration[4.2]
  def change
    create_table :noid_states do |t|
      t.text :state
      t.timestamps
    end
  end
end
