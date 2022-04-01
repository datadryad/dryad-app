class AddAuthorOrderToStashEngineAuthors < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_authors, :author_order, :integer, default: nil
  end
end
