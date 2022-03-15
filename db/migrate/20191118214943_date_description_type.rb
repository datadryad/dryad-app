# rubocop:disable Layout/LineLength
class DateDescriptionType < ActiveRecord::Migration[4.2]
  def up
    change_table :dcs_descriptions do |t|
      t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'technicalinfo', 'other', 'usage_notes', 'grant_number') DEFAULT NULL"
    end
    change_table :dcs_dates do |t|
      t.change :date_type, "ENUM('accepted', 'available', 'copyrighted', 'collected', 'created', 'issued', 'other', 'submitted', 'updated', 'valid', 'withdrawn') DEFAULT NULL"
    end
  end

  def down
    change_table :dcs_descriptions do |t|
      t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'other', 'usage_notes', 'grant_number') DEFAULT NULL"
    end
    change_table :dcs_dates do |t|
      t.change :date_type, "ENUM('accepted', 'available', 'copyrighted', 'collected', 'created', 'issued', 'submitted', 'updated', 'valid') DEFAULT NULL"
    end
  end
end
# rubocop:enable Layout/LineLength
