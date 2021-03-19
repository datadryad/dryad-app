class CreateStashEngineGenericFiles < ActiveRecord::Migration[5.2]
  def up
    create_table :stash_engine_generic_files, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci", force: :cascade do |t|
      t.text "upload_file_name", collation: "utf8mb4_bin"
      t.text "upload_content_type", collation: "utf8mb4_unicode_ci"
      t.bigint "upload_file_size"
      t.integer "resource_id"
      t.datetime "upload_updated_at"
      t.timestamps null: false
      t.string "file_state", limit: 7, type: "ENUM('created', 'copied', 'deleted')"
      t.text "url", collation: "utf8mb4_general_ci"
      t.integer "status_code"
      t.boolean "timed_out", default: false
      t.text "original_url", collation: "utf8mb4_general_ci"
      t.string "cloud_service"
      t.string "digest"
      t.string "digest_type", limit: 8, type: "ENUM('md5', 'sha-1', 'sha-256', 'sha-384', 'sha-512')"
      t.text "description"
      t.text "original_filename"
      t.string :type
      t.index ["file_state"], name: "index_stash_engine_generic_files_on_file_state"
      t.index ["resource_id"], name: "index_stash_engine_generic_files_on_resource_id"
      t.index ["upload_file_name"], name: "index_stash_engine_generic_files_on_upload_file_name", length: 50
      t.index ["url"], name: "index_stash_engine_generic_files_on_url", length: 50
    end
  end
end
