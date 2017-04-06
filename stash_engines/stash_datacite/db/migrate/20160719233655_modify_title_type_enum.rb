class ModifyTitleTypeEnum < ActiveRecord::Migration
  def change
    StashDatacite::Title.where(title_type: 'main').update_all(title_type: nil)
    change_column_default(:dcs_titles, :title_type, nil)
    change_table :dcs_titles do |t|
      t.change :title_type, "ENUM('alternative_title', 'subtitle', 'translated_title') DEFAULT NULL"
    end
  end
end
