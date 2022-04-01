class AddDeferredToEnumForZenodoCopy < ActiveRecord::Migration[4.2]
  def up
    change_table :stash_engine_zenodo_copies do |t|
      t.change :state, "ENUM('enqueued','replicating','finished','error','deferred') DEFAULT 'enqueued'"
    end
  end

  def down
    change_table :stash_engine_zenodo_copies do |t|
      t.change :state, "ENUM('enqueued','replicating','finished','error') DEFAULT 'enqueued'"
    end
  end
end
