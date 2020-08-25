class ModifyTitleTypeEnums < ActiveRecord::Migration[4.2]
  def change
    change_table :dcs_titles do |t|
      t.change :title_type, "ENUM('alternativetitle', 'subtitle', 'translatedtitle') DEFAULT NULL"
    end
  end
end
