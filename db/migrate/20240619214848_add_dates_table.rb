class AddDatesTable < ActiveRecord::Migration[7.0]
  ALL_IDENTIFIERS = <<-SQL.freeze
    INSERT IGNORE INTO stash_engine_process_dates (processable_id, processable_type, created_at) SELECT id, 'StashEngine::Identifier', created_at FROM stash_engine_identifiers
  SQL
  ALL_RESOURCES = <<-SQL.freeze
    INSERT IGNORE INTO stash_engine_process_dates (processable_id, processable_type, created_at) SELECT id, 'StashEngine::Resource', created_at FROM stash_engine_resources
  SQL
  def change
    create_table :stash_engine_process_dates do |t|
      t.integer :processable_id
      t.string :processable_type
      t.datetime :processing
      t.datetime :peer_review
      t.datetime :submitted
      t.datetime :curation_start
      t.datetime :curation_end
      t.datetime :approved
      t.datetime :withdrawn
      t.timestamps
    end
    add_index :stash_engine_process_dates, [:processable_id, :processable_type], unique: true, name: 
    'index_process_dates_on_processable_id_and_type'
    reversible do |dir|
      dir.up do
        execute ALL_IDENTIFIERS
        execute ALL_RESOURCES
        StashEngine::Identifier.unscoped.joins("INNER JOIN `stash_engine_resources` ON `stash_engine_resources`.`id` = `stash_engine_identifiers`.`latest_resource_id`").find_each do |identifier|
          identifier.resources.each do |resource|
            dates = {}
            status_changes = resource.curation_activities.pluck(:status, :created_at).uniq(&:first)
            status_changes.each_with_index do |c, i|
              dates[c.first.to_sym] = c.last if ['processing', 'peer_review', 'submitted', 'withdrawn'].include?(c.first)
              dates[:curation_start] = c.last if c.first == 'curation'
              dates[:curation_end] = c.last if i > 1 && status_changes[i - 1].first == 'curation'
              dates[:approved] = c.last if ['embargoed', 'published'].include?(c.first) 
            end
            resource.process_date.update(dates)
            id_dates = dates.delete_if { |k, _v| identifier.process_date.send(k).present? }
            unless id_dates.empty?
              identifier.process_date.update(id_dates)
              identifier.reload
            end
          end
        end
      end
      dir.down do; end
    end
  end
end
