class RemoveTmpChecksumsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :tmp_checksums
  end

  def down
    create_table "tmp_checksums", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
      t.text "ark"
      t.integer "version"
      t.text "path"
      t.integer "bytes"
      t.text "digest"
      t.datetime "created", precision: nil
      t.text "local_id"
    end
  end
end
