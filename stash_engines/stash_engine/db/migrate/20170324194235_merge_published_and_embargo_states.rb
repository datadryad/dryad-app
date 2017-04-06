class MergePublishedAndEmbargoStates < ActiveRecord::Migration
  def up
    change_table :stash_engine_resource_states do |t|
      # add 'submitted' state
      t.change :resource_state, <<-SQL
        ENUM (
               'in_progress',
               'processing',
               'published',
               'error',
               'embargoed',
               'submitted'
        ) DEFAULT 'in_progress'
      SQL

      # migrate existing records to 'submitted' state
      # note 'embargoed' should never have been used, but just in case
      StashEngine::ResourceState.connection.execute(
        <<-SQL
        UPDATE stash_engine_resource_states
           SET resource_state = 'submitted'
         WHERE resource_state IN ('published', 'embargoed')
        SQL
      )

      # remove obsolete states
      t.change :resource_state, <<-SQL
        ENUM (
               'in_progress',
               'processing',
               'error',
               'submitted'
        ) DEFAULT 'in_progress'
      SQL
    end
  end

  def down
    change_table :stash_engine_resource_states do |t|
      # add back 'published' and 'embargoed'
      t.change :resource_state, <<-SQL
        ENUM (
               'in_progress',
               'processing',
               'published',
               'error',
               'embargoed',
               'submitted'
        ) DEFAULT 'in_progress'
      SQL

      # migrate back to 'published' ('embargoed' was never used)
      StashEngine::ResourceState.connection.execute(
        <<-SQL
        UPDATE stash_engine_resource_states
           SET resource_state = 'published'
         WHERE resource_state = 'submitted'
      SQL
      )

      # remove 'submitted'
      t.change :resource_state, <<-SQL
        ENUM (
               'in_progress',
               'processing',
               'published',
               'error',
               'embargoed'
        ) DEFAULT 'in_progress'
      SQL
    end
  end
end
