class CreateStashEngineDownloadHistories < ActiveRecord::Migration
  def change
    create_table :stash_engine_download_histories do |t|
      t.string :ip_address, index: true
      t.text :user_agent
      t.references :resource, index: true
      t.references :file_upload, index: true
      t.column :state, "ENUM('downloading', 'finished') DEFAULT 'downloading'"
      t.timestamps null: false

      t.index :user_agent, length: { user_agent: 100 }
      t.index :state
    end
  end
end
