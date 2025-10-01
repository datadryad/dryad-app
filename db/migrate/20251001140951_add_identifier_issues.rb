class AddIdentifierIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_identifiers, :issues, :json
  end
end
