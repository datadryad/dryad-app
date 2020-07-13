class CreateStashEngineDownloadTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :stash_engine_download_tokens do |t|
      t.references :resource
      t.string :token, index: true
      t.datetime :available

      t.timestamps null: false
    end
  end
end
