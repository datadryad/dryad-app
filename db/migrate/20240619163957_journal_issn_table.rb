class JournalIssnTable < ActiveRecord::Migration[7.0]
  def change
    add_index :stash_engine_internal_data, [:identifier_id, :data_type], unique: false, name: 'index_internal_data_on_identifier_and_data_type'
    create_table :stash_engine_journal_issns, id: :string do |t|
      t.integer :journal_id
      t.timestamps
    end
    add_foreign_key :stash_engine_journal_issns, :stash_engine_journals, column: :journal_id
    reversible do |dir|
      dir.up do
        StashEngine::Journal.find_each do |j|
          issns = j.issn if j.issn.present? && j.issn.is_a?(Array)
          issns ||= JSON.parse(j.issn) if j.issn.present? && j.issn.start_with?('[')
          issns ||= [j.issn]
          issns.flatten.reject(&:blank?).each do |issn|
            StashEngine::JournalIssn.create(id: issn, journal_id: j.id)
          end
        end
        remove_index :stash_engine_journals, :issn
        remove_column :stash_engine_journals, :issn
      end
      dir.down do
        add_column :stash_engine_journals, :issn, :string
        StashEngine::Journal.find_each do |j|
          j.update(issn: j.issns.map(&:id).to_json)
        end
        add_index :stash_engine_journals, :issn
      end
    end
  end
end
