class AddPubStateToIdentifier < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      ALTER TABLE stash_engine_identifiers ADD pub_state
        enum('embargoed', 'published', 'withdrawn', 'unpublished');
    SQL
  end

  def down
    remove_column :stash_engine_identifiers, :pub_state, :enum
  end
end
