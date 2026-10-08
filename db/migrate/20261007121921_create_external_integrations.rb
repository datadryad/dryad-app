class CreateExternalIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :external_integrations do |t|
      t.integer :integrator_id
      t.string :integrator_type
      t.string :integration
      t.string :username
      t.string :password
      t.json :details

      t.timestamps
    end
  end
end
