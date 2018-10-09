class AddEmbargoTypeToStashEngineEmbargoes < ActiveRecord::Migration
  def change
    add_column :stash_engine_embargoes, :embargo_type, :string
  end
end
