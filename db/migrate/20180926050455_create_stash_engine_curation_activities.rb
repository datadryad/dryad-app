class CreateStashEngineCurationActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :stash_engine_curation_activities do |t|
      t.integer :identifier_id
      t.string :status
      t.integer :user_id
      t.string :note
      t.string :keywords

      t.timestamps null: false
    end
  end
end
