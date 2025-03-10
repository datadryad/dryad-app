class AddDatasetPubDate < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_identifiers, :publication_date, :datetime, after: :pub_state
    reversible do |dir|
      dir.up do
        StashEngine::Identifier.unscoped.publicly_viewable.find_each do |id|
          id.update(publication_date: id.resources.map(&:publication_date)&.reject(&:blank?)&.first || nil)
        end
      end
      dir.down do; end
    end
  end
end
