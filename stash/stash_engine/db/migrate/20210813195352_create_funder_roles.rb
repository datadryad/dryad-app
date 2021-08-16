class CreateFunderRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_funder_roles do |t|
      t.belongs_to :user
      t.string :funder_id
      t.string :funder_name
      t.string :role
      t.timestamps  
    end
  end
end
