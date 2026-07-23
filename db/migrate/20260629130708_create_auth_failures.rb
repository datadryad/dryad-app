class CreateAuthFailures < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_failures do |t|
      t.string :ip
      t.text :user_agent
      t.string :error_type
      t.integer :user_id
      t.text :url
      t.json :params

      t.timestamps
    end
  end
end
