class CreateStashEngineJournalOrganizations < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_journal_organizations do |t|
      t.string :name
      t.string :contact
      t.integer :parent_org_id
      t.string :type
      t.timestamps
    end

    add_column :stash_engine_journals, :sponsor_id, :integer
    add_column :stash_engine_journal_roles, :journal_organization_id, :integer
    
  end
end
