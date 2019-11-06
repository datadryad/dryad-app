class DropStashEngineEmbargoes < ActiveRecord::Migration
  def change
    drop_table :stash_engine_embargoes
  end
end
