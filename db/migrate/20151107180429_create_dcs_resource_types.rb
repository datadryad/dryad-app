class CreateDcsResourceTypes < ActiveRecord::Migration
  def change
    create_table :dcs_resource_types do |t|
      t.column :resource_type, "ENUM('spreadsheet', 'image', 'sound', 'audiovisual',
                                     'text', 'software', 'multiple_types', 'other',
                                     'collection', 'dataset', 'event', 'interactive_resource',
                                     'model', 'physical_object', 'service', 'workflow') DEFAULT NULL"
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end

