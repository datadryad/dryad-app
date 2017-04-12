# This migration comes from stash_datacite (originally 20160720000727)
class ModifyTitleTypeEnums < ActiveRecord::Migration
  def change
    change_table :dcs_titles do |t|
      t.change :title_type, "ENUM('alternativetitle', 'subtitle', 'translatedtitle') DEFAULT NULL"
    end
  end
end
