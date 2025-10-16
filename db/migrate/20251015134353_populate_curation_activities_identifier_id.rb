class PopulateCurationActivitiesIdentifierId < ActiveRecord::Migration[8.0]

  def up
    ActiveRecord::Base.connection.execute <<~SQL
      UPDATE stash_engine_curation_activities
      JOIN stash_engine_resources on stash_engine_curation_activities.resource_id = stash_engine_resources.id
      SET stash_engine_curation_activities.identifier_id = stash_engine_resources.identifier_id
    SQL
  end

  def down
    ActiveRecord::Base.connection.execute('UPDATE stash_engine_curation_activities SET identifier_id = NULL')
  end
end
