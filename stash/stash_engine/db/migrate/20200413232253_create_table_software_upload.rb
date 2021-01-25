class CreateTableSoftwareUpload < ActiveRecord::Migration[4.2]
  def up
    # starts the table with the same structure as the file_upload table may diverge after this
    execute 'CREATE TABLE stash_engine_software_uploads LIKE stash_engine_file_uploads'
  end

  def down
    # down just removes this table since it didn't exist before this
    execute 'DROP TABLE stash_engine_software_uploads'
  end
end
