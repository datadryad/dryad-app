class CreateJournalRoles < ActiveRecord::Migration[4.2]
  def up
    create_table :stash_engine_journal_roles do |t|
      t.belongs_to :journal
      t.belongs_to :user
      t.string :role
      t.timestamps
    end
  end

  def down
    drop_table :stash_engine_journal_roles
  end
end
