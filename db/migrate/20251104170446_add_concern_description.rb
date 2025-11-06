class AddConcernDescription < ActiveRecord::Migration[8.0]
  def up
    change_table :dcs_descriptions do |t|
      t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'technicalinfo', 'other', 'hsi_statement', 'changelog', 'concern') DEFAULT NULL"
    end
  end

  def down
    change_table :dcs_descriptions do |t|
      t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'technicalinfo', 'other', 'hsi_statement', 'changelog') DEFAULT NULL"
    end
  end
end
