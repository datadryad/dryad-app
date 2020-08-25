class AddEmbargoTypeToStashEngineEmbargoes < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_embargoes, :embargo_type, :string
  end
end
