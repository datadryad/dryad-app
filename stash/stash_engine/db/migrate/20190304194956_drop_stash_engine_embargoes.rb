class DropStashEngineEmbargoes < ActiveRecord::Migration[4.2]
  def change
    drop_table :stash_engine_embargoes
  end
end
