class AddDatapaper < ActiveRecord::Migration[4.2]
  def up
    change_table :dcs_resource_types do |t|
      t.change :resource_type_general, "ENUM('audiovisual','collection','datapaper','dataset','event','image','interactiveresource','model'," \
                                       "'physicalobject','service','software','sound','text','workflow','other') DEFAULT 'dataset'"
    end
  end

  def down
    change_table :dcs_resource_types do |t|
      t.change :resource_type_general, "ENUM('audiovisual','collection','dataset','event','image','interactiveresource','model'," \
                                       "'physicalobject','service','software','sound','text','workflow','other') DEFAULT 'dataset'"
    end
  end
end
