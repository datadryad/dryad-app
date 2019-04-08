class ModifyTitleTypeEnum < ActiveRecord::Migration
  def change
    execute QUERY1
    execute QUERY2
  end

  QUERY1 = <<-eos.freeze
    UPDATE dcs_titles SET title_type = NULL
    WHERE title_type = 'main'
  eos

  QUERY2 = <<-eos.freeze
    ALTER TABLE dcs_titles MODIFY COLUMN `title_type` enum('alternativetitle','subtitle','translatedtitle') DEFAULT NULL;
  eos
end
