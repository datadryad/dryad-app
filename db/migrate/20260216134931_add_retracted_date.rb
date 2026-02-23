class AddRetractedDate < ActiveRecord::Migration[8.0]
  def up
    add_column :stash_engine_process_dates, :retracted, :datetime, after: :withdrawn
    execute <<-SQL.freeze
      ALTER TABLE stash_engine_identifiers MODIFY COLUMN `pub_state` enum('embargoed', 'published', 'withdrawn', 'unpublished', 'retracted');
    SQL
  end

  def down
    remove_column :stash_engine_process_dates, :retracted, :datetime
    execute <<-SQL.freeze
      ALTER TABLE stash_engine_identifiers MODIFY COLUMN `pub_state` enum('embargoed', 'published', 'withdrawn', 'unpublished');
    SQL
  end
end
