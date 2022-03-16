class AddResourceTypeEnums < ActiveRecord::Migration[4.2]
  def change
    change_table :dcs_resource_types do |t|
      t.change :resource_type, "ENUM('audiovisual', 'collection', 'dataset', 'event', 'image', 'interactiveresource', " \
                               "'model', 'physicalobject', 'service', 'software', 'sound', 'text', 'workflow', 'other') DEFAULT 'dataset'"
    end
  end
end
