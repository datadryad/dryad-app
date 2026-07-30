class AddResearchIntegrity < ActiveRecord::Migration[8.0]
  def change
    create_table :research_integrity_cases do |t|
      t.bigint :identifier_id
      t.bigint :curation_activity_id
      t.text :notes
      t.boolean :resolved, default: false
      t.timestamps
    end
  end
end
