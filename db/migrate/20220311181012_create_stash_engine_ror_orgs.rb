class CreateStashEngineRorOrgs < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_ror_orgs do |t|
      t.string :ror_id
      t.string :name
      t.string :home_page
      t.string :country
      t.json :acronyms
      t.json :aliases
      t.timestamps  
    end
  end
end
