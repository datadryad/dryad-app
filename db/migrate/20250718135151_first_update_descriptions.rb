class FirstUpdateDescriptions < ActiveRecord::Migration[8.0]
  def up
    change_table :dcs_descriptions do |t|
      t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'technicalinfo', 'other', 'usage_notes', 'hsi_statement', 'changelog') DEFAULT NULL"
    end
  end

  def down
    change_table :dcs_descriptions do |t|
      t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'technicalinfo', 'other', 'usage_notes', 'grant_number') DEFAULT NULL"
    end
  end
end
