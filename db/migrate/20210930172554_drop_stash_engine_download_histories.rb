class DropStashEngineDownloadHistories < ActiveRecord::Migration[5.2]
  def change
    drop_table :stash_engine_download_histories
  end
end
