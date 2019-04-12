class CreateStashEngineOrganizations < ActiveRecord::Migration
  def change
    create_table :stash_engine_organizations do |t|

      t.string  :identifier, index: true   # ROR identifier URI
      t.string  :name, index: true         # Will store ROR long_name
      t.string  :country                   # Will store the ROR country
      t.text    :aliases                   # Stores a JSON array of aliases pulled from ROR
      t.text    :acronyms                  # Stores a JSON array of acronyms pulled from ROR
      t.boolean :candidate, default: false # Records added by the UI that need to be curated

      t.timestamps
    end
  end
end
