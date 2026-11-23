class IndexStashEngineAuthorsOnAuthorEmail < ActiveRecord::Migration[8.0]
  def change
    add_index :stash_engine_authors, :author_email
  end
end
