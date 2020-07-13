class AddSearchWordsToIdentifier < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_identifiers, :search_words, :text
    add_index :stash_engine_identifiers, :search_words, name: 'admin_search_index', type: :fulltext
  end
end
