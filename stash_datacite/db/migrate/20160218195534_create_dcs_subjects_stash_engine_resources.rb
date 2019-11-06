class CreateDcsSubjectsStashEngineResources < ActiveRecord::Migration
  def change
    create_table :dcs_subjects_stash_engine_resources do |t|
      t.integer :resource_id
      t.integer :subject_id

      t.timestamps null: false
    end
  end
end
