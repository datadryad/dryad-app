class CreateJournalRoles < ActiveRecord::Migration
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
