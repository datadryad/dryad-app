class CreateStashEngineExternalDependencies < ActiveRecord::Migration
  def change
    create_table :stash_engine_external_dependencies do |t|
      t.string      :abbreviation, index: true
      t.string      :name
      t.string      :description
      t.integer     :status, default: 1
      t.text        :documentation
      t.text        :error_message
      t.boolean     :internally_managed, default: false
      t.timestamps
    end
  end
end
