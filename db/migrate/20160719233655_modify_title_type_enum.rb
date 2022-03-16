class ModifyTitleTypeEnum < ActiveRecord::Migration[4.2]
  def change
    execute QUERY1
    execute QUERY2
  end

  QUERY1 = <<-SQL.freeze
    UPDATE dcs_titles SET title_type = NULL
    WHERE title_type = 'main'
  SQL

  QUERY2 = <<-SQL.freeze
    ALTER TABLE dcs_titles MODIFY COLUMN `title_type` enum('alternativetitle','subtitle','translatedtitle') DEFAULT NULL;
  SQL
end
