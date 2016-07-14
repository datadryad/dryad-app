class AddOtherToDescriptionEnum < ActiveRecord::Migration
  def change
    t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'other', 'usage_notes') DEFAULT NULL"
  end
end
