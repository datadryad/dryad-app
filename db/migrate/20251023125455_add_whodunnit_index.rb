class AddWhodunnitIndex < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      ALTER TABLE paper_trail_versions ADD INDEX paper_trail_whodunnit_idx (whodunnit), ALGORITHM=INPLACE, LOCK=NONE;
    SQL
  end

  def down
    remove_index :paper_trail_versions, column: :whodunnit, name: "paper_trail_whodunnit_idx"
  end
end
