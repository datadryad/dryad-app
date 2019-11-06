class AddIdentifierIdToStashEngineShares < ActiveRecord::Migration
  def up
    add_column :stash_engine_shares, :identifier_id, :integer
    add_index :stash_engine_shares, :identifier_id

    query = <<~HEREDOC
      UPDATE stash_engine_shares sh2
      JOIN
        (SELECT sh.id, res.identifier_id
        FROM stash_engine_resources res
        JOIN stash_engine_shares sh
        ON res.id = sh.resource_id) sh3
      ON sh2.id = sh3.id
      SET sh2.identifier_id = sh3.identifier_id;
    HEREDOC
    execute query

    # after we see data is good in production and all code changed, we can remove the resource_id from the table
  end

  def down
    remove_column :stash_engine_shares, :identifier_id, :integer
  end
end
