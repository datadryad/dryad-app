class AddMerrittDatasetStatusToStashEngineExternalDependencies < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      DELETE FROM stash_engine_external_dependencies WHERE abbreviation = 'notifier'
    SQL
    execute <<-SQL
      INSERT INTO stash_engine_external_dependencies
        (abbreviation, `name`, description, status, documentation, error_message, internally_managed, created_at, updated_at)
        VALUES 
          ('submission_status', 'Merritt submission status',
            'Hits the Merritt API endpoint to check if outstanding submissions are finished yet', 1,
            "Checks the logs at <RAILS_ROOT>/log/merritt_status_updater.log to be sure it has been checked recently. This is a daemon started by system.d which calls the a rake task like 'RAILS_ENV=development rails merritt_status:update'",
            NULL, 1, '2021-05-26 22:38:37', '2022-11-17 22:40:10')
    SQL
  end

  def down
    execute <<-SQL
      INSERT INTO stash_engine_external_dependencies
        (abbreviation, `name`, description, status, documentation, error_message, internally_managed, created_at, updated_at)
        VALUES 
          ('notifier', 'Stash Notifier',
            'The service that lets Dryad know when Merritt has finished processing (via the OAI-PMH feed)', 1,
            "If the OAI-PMH feed is working and the item is present, check the stash-notifier logs.  A pid file that was never removed may prevent the notifier from processing additional items since it believes a notifier instance is already running.  You may need to remove the pid file or look to see if there is some problem with the notifier.  Maybe a server got shut down in the middle of a run so the notifier didn't have a chance to remove it's own pid.",
            NULL, 1, '2021-05-26 22:38:37', '2022-11-17 22:40:10')
    SQL
    execute <<-SQL
      DELETE FROM stash_engine_external_dependencies WHERE abbreviation = 'submission_status'
    SQL
  end
end
