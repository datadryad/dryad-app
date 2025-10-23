class AddWhodunnitIndex < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      ALTER TABLE paper_trail_versions ADD INDEX index_paper_trail_versions_on_whodunnit (whodunnit), ALGORITHM=INPLACE, LOCK=NONE;
    SQL
  end

  def down
    remove_index :paper_trail_versions, column: :whodunnit, name: "index_paper_trail_versions_on_whodunnit"
  end
end
